extends CharacterBody3D

@export var speed := 3.0
@export var acceleration := 20.0
@export var attack_range := 10.0  # Jarak maksimum untuk menyerang
@export var stop_distance := 8.0  # Jarak minimum sebelum musuh mulai mundur

@onready var anim_player: AnimationPlayer = $WraithModel/AnimationPlayer
@onready var model: Node3D = $WraithModel
@onready var detection_area: Area3D = $DetectionArea

@onready var health_bar: Control = $HealthBar
@onready var camera: Camera3D = null

# status and damage
@onready var wraith_status = preload("res://scripts/data/Wraith/WraithStatus.gd").new()
@onready var wraith_damage_system = preload("res://scripts/data/Wraith/WraithDamage.gd").new()


var velocity_local := Vector3.ZERO
var direction := Vector3.ZERO
var is_attacking := false
var current_attack_anim := ""

var player: Node3D = null
var support: Node3D = null  # Add support reference
var current_target: Node3D = null  # Current target to attack

# Damage tracking
var damage_sources = {}  # Dictionary to track damage from each source
var damage_tracking_timeout = 5.0  # Time in seconds to remember damage sources
var last_damage_time = 0.0  # Last time damage was taken

var drl_action = {}
var drl_interval := 0.5 # seconds between DRL queries
var drl_time_accum := 0.0

# Combo tracking
var combo_history = []
var last_damage_dealt = 0
var last_action_time = 0
var combo_timeout = 2.0  # seconds before combo resets

@onready var http_request := $HTTPRequest

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	anim_player.animation_finished.connect(_on_animation_finished)
	add_child(wraith_damage_system)
	wraith_damage_system.set_wraith_status(wraith_status)
	add_to_group("wraith")
	http_request.request_completed.connect(_on_HTTPRequest_request_completed)
	
	wraith_damage_system.owner = self

func _process(delta):
	# Update combo timeout
	if Time.get_ticks_msec() - last_action_time > combo_timeout * 1000:
		combo_history.clear()
	
	# Update damage tracking timeout
	if Time.get_ticks_msec() - last_damage_time > damage_tracking_timeout * 1000:
		damage_sources.clear()
	
	var camera = get_viewport().get_camera_3d()
	if health_bar and camera:
		var head_offset = Vector3(-1.5, 2.5, 0)
		var world_pos = global_transform.origin + head_offset
		var screen_pos = camera.unproject_position(world_pos)
		health_bar.global_position = screen_pos
		wraith_status.set_wraith_status(health_bar)

func _physics_process(delta):
	drl_time_accum += delta
	if drl_time_accum >= drl_interval:
		send_drl_request()
		drl_time_accum = 0.0

	handle_ai()
	move_enemy(delta)
	play_animation()
	rotate_model()

# BEGIN DRL LOGIC
func send_drl_train(state: Dictionary, action: int, next_state: Dictionary):
	# Batasi action hanya ke [0, 1, 2, 3] sesuai PPO
	if action > 3: 
		action = 0  # fallback jadi attack/idle di PPO

	# Calculate damage dealt in this action
	var damage_dealt = last_damage_dealt
	last_damage_dealt = 0  # Reset for next action

	var train_data = {
		"state": state.values(),
		"action": action,
		"next_state": next_state.values(),
		"damage_dealt": damage_dealt,
		"combo_history": combo_history
	}
	var json = JSON.new()
	var json_train = json.stringify(train_data)

	var http_train = HTTPRequest.new()
	add_child(http_train)
	http_train.request(
		"http://0.0.0.0:5000/train",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_train
	)


func send_drl_request():
	var state = build_state_dict()
	var json = JSON.new()
	var json_state = json.stringify(state)
	
	# Add detailed state logging
	print("=== DRL State Debug ===")
	print("State being sent to DRL server:")
	for key in state.keys():
		print("%s: %s" % [key, state[key]])
	print("=====================")
	
	http_request.request(
		"http://0.0.0.0:8000/predict",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		json_state
	)

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			drl_action = json.get_data()
			# Add response logging
			print("=== DRL Response Debug ===")
			print("Raw response: %s" % body.get_string_from_utf8())
			print("Parsed action: %s" % str(drl_action))
			print("=====================")
		else:
			print("Failed to parse DRL response")
			drl_action = {}
	else:
		print("DRL request failed with code: %d" % response_code)
		drl_action = {}

func build_state_dict() -> Dictionary:
	if not is_instance_valid(current_target):
		return {
			"enemy_hp": wraith_status.hp if wraith_status else 0,
			"enemy_mp": wraith_status.mp if wraith_status else 0,
			"player_hp": 0,
			"player_mp": 0,
			"distance": 0,
			"player_dps": 0,
			"damage_taken": wraith_status.self_damage if wraith_status and wraith_status.self_damage else 0,
			"can_summon": false,
			"can_tornado": false,
			"can_full_tornado": false,
			"summon_count": 0,
			"tornado_cd": 0,
			"summon_cd": 0
		}

	var to_target = current_target.global_transform.origin - global_transform.origin
	var distance = to_target.length()
	
	print("=== Distance Debug ===")
	print("Current target: %s" % (current_target.name if current_target else "none"))
	print("Distance to target: %.2f" % distance)
	print("Target position: %s" % str(current_target.global_transform.origin))
	print("Wraith position: %s" % str(global_transform.origin))
	print("====================")
	
	# Get target status based on whether it's player or support
	var target_hp = 0
	var target_mp = 0
	var target_dps = 0
	
	if current_target.is_in_group("player"):
		target_hp = current_target.kyle_status.hp if current_target.kyle_status else 100
		target_mp = current_target.kyle_status.mp if current_target.kyle_status else 100
		target_dps = current_target.kyle_status.self_damage if current_target.kyle_status else 10
	elif current_target.is_in_group("support"):
		target_hp = current_target.nora_status.hp if current_target.nora_status else 100
		target_mp = current_target.nora_status.mp if current_target.nora_status else 100
		target_dps = current_target.nora_status.self_damage if current_target.nora_status else 10
	
	# Debug skill availability
	print("=== Skill Availability Debug ===")
	print("MP: %d/%d" % [wraith_status.mp if wraith_status else 0, wraith_status.max_mp if wraith_status else 0])
	print("Summon:")
	print("- MP check: %s" % (wraith_status and wraith_status.mp >= wraith_damage_system.SUMMON_COST))
	print("- Active summons: %d/%d" % [wraith_damage_system.active_summons.size() if wraith_damage_system else 0, wraith_damage_system.MAX_SUMMONS if wraith_damage_system else 0])
	print("- Cooldown: %s" % (not wraith_damage_system.summon_on_cooldown if wraith_damage_system else false))
	print("Tornado:")
	print("- MP check: %s" % (wraith_damage_system and wraith_status.mp >= wraith_damage_system.TORNADO_COST))
	print("- Distance check: %s" % (distance <= 10))
	print("- Cooldown: %s" % (not wraith_damage_system.tornado_on_cooldown if wraith_damage_system else false))
	print("Full Tornado:")
	print("- MP check: %s" % (wraith_damage_system and wraith_status.mp >= wraith_damage_system.TORNADO_COST))
	print("- Distance check: %s" % (distance < 5))
	print("- Cooldown: %s" % (not wraith_damage_system.full_tornado_on_cooldown if wraith_damage_system else false))
	print("====================")
	
	return {
		"enemy_hp": wraith_status.hp if wraith_status else 0,
		"enemy_mp": wraith_status.mp if wraith_status else 0,
		"player_hp": target_hp,
		"player_mp": target_mp,
		"distance": distance,
		"player_dps": target_dps,
		"damage_taken": wraith_status.self_damage if wraith_status and wraith_status.self_damage else 0,
		"can_summon": wraith_status and wraith_damage_system and wraith_status.mp >= wraith_damage_system.SUMMON_COST and wraith_damage_system.active_summons.size() < wraith_damage_system.MAX_SUMMONS and not wraith_damage_system.summon_on_cooldown,
		"can_tornado": wraith_damage_system and wraith_status.mp >= wraith_damage_system.TORNADO_COST and not wraith_damage_system.tornado_on_cooldown and distance <= 10,
		"can_full_tornado": wraith_damage_system and wraith_status.mp >= wraith_damage_system.TORNADO_COST and not wraith_damage_system.full_tornado_on_cooldown and distance < 5,
		"summon_count": wraith_damage_system.active_summons.size() if wraith_damage_system else 0,
		"tornado_cd": wraith_damage_system.TORNADO_COOLDOWN if wraith_damage_system else 0,
		"summon_cd": wraith_damage_system.SUMMON_COOLDOWN if wraith_damage_system else 0
	}

func handle_ai():
	if not is_instance_valid(current_target) or is_attacking:
		direction = Vector3.ZERO
		return

	var to_target = current_target.global_transform.origin - global_transform.origin
	var distance = to_target.length()
	var state = build_state_dict()
	var action_taken = 0

	if drl_action.has("action"):
		print("AI (DRL): Using DRL action: %s" % drl_action["action"])
		var proposed_action = -1
		var player_style = drl_action.get("player_style", "balanced")
		var melee_percentage = drl_action.get("melee_percentage", 0.5)
		
		print("Player Style Analysis:")
		print("- Style: %s" % player_style)
		print("- Melee Percentage: %.2f" % melee_percentage)
		print("- Combo History: %s" % str(combo_history))
		
		match drl_action["action"]:
			"summon":
				proposed_action = 0
			"tornado":
				proposed_action = 1
			"full_tornado":
				proposed_action = 2
			"retreat":
				proposed_action = 3
			"chase":
				proposed_action = 4
			_:
				proposed_action = 0

		# Update combo history
		if combo_history.size() > 0:
			var last_action = combo_history[-1]
			# Update damage tracking
			if last_action == "summon" and proposed_action == "tornado":
				last_damage_dealt = wraith_damage_system.TORNADO_DAMAGE
			elif last_action == "tornado" and proposed_action == "full_tornado":
				last_damage_dealt = wraith_damage_system.FULL_TORNADO_DAMAGE
			elif last_action == "full_tornado" and proposed_action == "retreat":
				last_damage_dealt = 0  # No damage for retreat

		combo_history.append(drl_action["action"])
		if combo_history.size() > 3:  # Keep last 3 actions
			combo_history.pop_front()
		last_action_time = Time.get_ticks_msec()

		# Execute the adapted action
		match proposed_action:
			0:  # Summon
				print("AI (DRL): Summoning minion.")
				start_summon()
				action_taken = 0
			1:  # Tornado
				print("AI (DRL): Casting tornado.")
				start_tornado()
				action_taken = 1
			2:  # Full Tornado
				print("AI (DRL): Casting full tornado.")
				start_full_tornado()
				action_taken = 2
			3:  # Retreat
				print("AI (DRL): Retreating from target.")
				direction = -to_target.normalized()
				action_taken = 3
			4:  # Chase
				print("AI (DRL): Chasing target.")
				direction = to_target.normalized()
				action_taken = 4
	else:
		print("AI (Fallback): DRL action not available, using conventional logic.")
		
		# Summon logic
		if wraith_status and wraith_damage_system:
			if wraith_status.mp >= wraith_damage_system.SUMMON_COST \
				and wraith_damage_system.active_summons.size() < wraith_damage_system.MAX_SUMMONS \
				and not wraith_damage_system.summon_on_cooldown:
				print("AI (Fallback): Summoning minion.")
				start_summon()
				action_taken = 0

			# Full Tornado logic
			elif not wraith_damage_system.full_tornado_on_cooldown and distance < 5:
				print("AI (Fallback): Using full tornado.")
				start_full_tornado()
				action_taken = 2

			# Tornado logic
			elif not wraith_damage_system.tornado_on_cooldown and distance <= 10:
				print("AI (Fallback): Using tornado.")
				start_tornado()
				action_taken = 1

		# Basic attack logic (only in fallback)
		if distance <= attack_range and distance >= stop_distance:
			print("AI (Fallback): Attacking target.")
			direction = Vector3.ZERO
			start_attack("wraith-magic-attack")
			action_taken = 0

		# Retreat logic
		elif distance < stop_distance:
			print("AI (Fallback): Retreating from target.")
			direction = -to_target.normalized()
			action_taken = 3

		# Chase logic
		else:
			print("AI (Fallback): Chasing target.")
			direction = to_target.normalized()
			action_taken = 4

	# Build next state after action for PPO training report
	var next_state = build_state_dict()
	send_drl_train(state, action_taken, next_state)

	# Log lengkap untuk debug
	print("AI Log: State=%s | ActionTaken=%d | NextState=%s | Combo=%s" % [
		str(state), 
		action_taken, 
		str(next_state),
		str(combo_history)
	])


# END DRL LOGIC

func move_enemy(delta):
	if is_attacking:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target_velocity = direction * speed
	velocity_local = velocity_local.lerp(target_velocity, acceleration * delta)

	velocity.x = velocity_local.x
	velocity.z = velocity_local.z
	move_and_slide()

func play_animation():
	if is_attacking:
		if not anim_player.is_playing() or anim_player.current_animation != current_attack_anim:
			anim_player.play(current_attack_anim)
		return

	if direction.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "wraith-standar-walk":
			anim_player.play("wraith-standar-walk")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "wraith-idle":
			anim_player.play("wraith-idle")

func rotate_model():
	if is_attacking and is_instance_valid(current_target):
		# Saat menyerang, selalu menghadap ke target
		var to_target = (current_target.global_transform.origin - global_transform.origin).normalized()
		var target_yaw = atan2(to_target.x, to_target.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)
	elif direction.length() > 0.1:
		# Saat berjalan, menghadap ke arah gerakan
		var target_yaw = atan2(direction.x, direction.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)


func start_attack(anim_name: String):
	is_attacking = true
	current_attack_anim = anim_name
	anim_player.speed_scale = 0.3
	anim_player.play(current_attack_anim)

func start_tornado():
	is_attacking = true
	anim_player.play("wraith-magic-attack")
	await anim_player.animation_finished
	wraith_damage_system.perform_tornado_skill()
	is_attacking = false

func start_full_tornado():
	is_attacking = true
	anim_player.play("wraith-magic-attack")
	await anim_player.animation_finished
	wraith_damage_system.perform_full_tornado_skill(10, 0.5)
	is_attacking = false

func start_summon():
	is_attacking = true
	current_attack_anim = "wraith-magic-attack" # Pastikan kamu punya animasi summon
	anim_player.speed_scale = 0.5
	anim_player.play(current_attack_anim)

	# Jalankan summon setelah delay kecil supaya animasi jalan
	await get_tree().create_timer(1).timeout

	if wraith_damage_system:
		wraith_damage_system.perform_summon(get_parent(), global_transform.origin)


func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		player = body
		if not current_target:
			current_target = body
		if wraith_damage_system:
			wraith_damage_system.set_player_reference(player)
	elif body.is_in_group("support"):
		support = body
		if not current_target:
			current_target = body

func _on_body_exited(body: Node):
	if body == player:
		player = null
		if current_target == body:
			current_target = support if is_instance_valid(support) else null
	elif body == support:
		support = null
		if current_target == body:
			current_target = player if is_instance_valid(player) else null

func take_damage(amount: int, source: Node = null):
	wraith_status.take_damage(amount)
	last_damage_time = Time.get_ticks_msec()
	
	# Track damage source
	if source:
		if not damage_sources.has(source):
			damage_sources[source] = 0
		damage_sources[source] += amount
		
		print("=== Damage Tracking Debug ===")
		print("Damage taken: %d from %s" % [amount, source.name if source else "unknown"])
		print("Current damage sources:")
		for src in damage_sources:
			print("- %s: %d damage" % [src.name if src else "unknown", damage_sources[src]])
		print("=========================")
		
		# Update target if this source is doing more damage
		update_target()
	
	if wraith_status.is_dead():
		die()

func update_target():
	# Find the source doing the most damage
	var highest_damage = 0
	var highest_damage_source = null
	
	print("=== Target Update Debug ===")
	print("Current target: %s" % (current_target.name if current_target else "none"))
	print("Damage sources:")
	for source in damage_sources:
		print("- %s: %d damage" % [source.name if source else "unknown", damage_sources[source]])
		if damage_sources[source] > highest_damage:
			highest_damage = damage_sources[source]
			highest_damage_source = source
	
	# Update current target if we found a higher damage source
	if highest_damage_source and highest_damage_source != current_target:
		print("Switching target to: %s (damage: %d)" % [highest_damage_source.name, highest_damage])
		current_target = highest_damage_source
		player = current_target if current_target.is_in_group("player") else player
		support = current_target if current_target.is_in_group("support") else support
	print("=========================")

func die():
	queue_free()
