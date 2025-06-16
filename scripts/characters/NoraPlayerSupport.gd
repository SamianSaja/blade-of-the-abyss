extends CharacterBody3D

@export var speed := 3.0
@export var acceleration := 20.0
@export var attack_range := 10.0
@export var stop_distance := 2.5  # Jarak aman saat mengikuti player
@export var retreat_distance := 1.0  # Terlalu dekat → mundur
@export var dodge_distance := 3.0  # Jarak untuk menghindar dari musuh
@export var max_attack_distance := 15.0  # Jarak maksimum untuk menyerang

@onready var anim_player: AnimationPlayer = $NoraModel/AnimationPlayer
@onready var model: Node3D = $NoraModel
@onready var detection_area: Area3D = $DetectionAreaNora

@onready var nora_status = preload("res://scripts/data/Nora/NoraStatus.gd").new()
@onready var nora_damage_system = preload("res://scripts/data/Nora/NoraDamage.gd").new()

var velocity_local := Vector3.ZERO
var direction := Vector3.ZERO
var is_attacking := false
var current_attack_anim := ""
var is_dodging := false
var dodge_direction := Vector3.ZERO
var is_hiding := false
var is_waiting_for_mp := false
var mp_recovery_timer := 0.0

var player: Node3D = null
var target_enemy: Node3D = null
var detected_enemies: Array[Node3D] = []

# Skill variables
var ice_sword_cooldown := 3.0  # Cooldown skill 1: 3 detik
var ice_sword_on_cooldown := false
var ice_sword_scene := preload("res://scenes/characters/Effects/NoraIceSwordSkillOne.tscn")
var ice_sword_rain_cooldown := 8.0  # Cooldown skill 2: 8 detik
var ice_sword_rain_on_cooldown := false
var ice_sword_rain_scene := preload("res://scenes/characters/Effects/NoraIceSwordSkillTwo.tscn")
var blue_ring_scene := preload("res://scenes/characters/Effects/BlueRingEffect.tscn")

func _ready():
	add_to_group("support")
	# status and damage
	add_child(nora_status)
	add_child(nora_damage_system)
	nora_damage_system.set_support_status(nora_status)

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	handle_ai()
	move_enemy(delta)
	play_animation()
	rotate_model()

func handle_ai():
	if is_attacking or is_dodging:
		return

	# Update detected enemies list
	detected_enemies = detected_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	# Handle low MP - retreat to safe position
	if nora_status.mp < 10:
		is_hiding = true
		if is_instance_valid(player) and is_instance_valid(self):
			var to_player = player.global_transform.origin - global_transform.origin
			var dist_player = to_player.length()
			
			# Cari posisi aman (tidak terlalu dekat dengan musuh dan tidak terlalu jauh dari Kyle)
			var min_dist_from_enemy = 8.0  # Jarak minimum dari musuh
			var max_dist_from_kyle = 12.0  # Jarak maksimum dari Kyle
			
			# Jika ada musuh terdekat, hindari mereka
			if detected_enemies.size() > 0:
				var closest_enemy = null
				var closest_dist = INF
				for enemy in detected_enemies:
					if is_instance_valid(enemy) and is_instance_valid(self):
						var dist = global_transform.origin.distance_to(enemy.global_transform.origin)
						if dist < closest_dist:
							closest_dist = dist
							closest_enemy = enemy
				
				if is_instance_valid(closest_enemy) and is_instance_valid(self):
					var to_enemy = global_transform.origin - closest_enemy.global_transform.origin
					
					# Jika terlalu dekat dengan musuh, menjauh
					if closest_dist < min_dist_from_enemy:
						direction = to_enemy.normalized()
						return
			
			# Jika terlalu jauh dari Kyle, dekati
			if dist_player > max_dist_from_kyle:
				direction = to_player.normalized()
			# Jika dalam jarak aman, berhenti
			else:
				direction = Vector3.ZERO
		return
	else:
		is_hiding = false
	
	# If no target but have detected enemies, choose closest one
	if not is_instance_valid(target_enemy) and detected_enemies.size() > 0:
		var closest_enemy = null
		var closest_dist = INF
		for enemy in detected_enemies:
			if is_instance_valid(enemy) and is_instance_valid(self):
				var dist = global_transform.origin.distance_to(enemy.global_transform.origin)
				if dist < closest_dist:
					closest_dist = dist
					closest_enemy = enemy
		target_enemy = closest_enemy

	# Prioritaskan enemy jika masih dalam jarak
	if is_instance_valid(target_enemy) and is_instance_valid(self):
		var to_enemy = target_enemy.global_transform.origin - global_transform.origin
		var dist_enemy = to_enemy.length()

		# Check if enemy is attacking and we're too close
		if dist_enemy < dodge_distance:
			perform_dodge(to_enemy)
			return

		# If enemy is too far, find new target
		if dist_enemy > max_attack_distance:
			target_enemy = null
			return

		if dist_enemy <= attack_range:
			# Check if we need to retreat (low MP)
			if nora_status.mp < 10:
				is_hiding = true
				if is_instance_valid(player) and is_instance_valid(self):
					var to_player = player.global_transform.origin - global_transform.origin
					var dist_player = to_player.length()
					
					# Jika terlalu dekat dengan musuh, menjauh
					if dist_enemy < 8.0:
						direction = -to_enemy.normalized()
					# Jika terlalu jauh dari Kyle, dekati
					elif dist_player > 12.0:
						direction = to_player.normalized()
					# Jika dalam jarak aman, berhenti
					else:
						direction = Vector3.ZERO
				return
				
			# Try to use ice sword rain skill if not on cooldown and has enough MP
			if not ice_sword_rain_on_cooldown and nora_status.mp >= 20:
				perform_ice_sword_rain_skill(target_enemy)
				return
			# Try to use single ice sword skill if not on cooldown and has enough MP
			elif not ice_sword_on_cooldown and nora_status.mp >= 10:
				perform_ice_sword_skill(target_enemy)
				return
			
			# If can't use skill, maintain safe distance
			if dist_enemy < stop_distance:
				direction = -to_enemy.normalized()
			else:
				direction = Vector3.ZERO
		else:
			# Dekati enemy jika belum cukup dekat
			direction = to_enemy.normalized()
			return

	# Jika tidak ada enemy, dekati player
	elif is_instance_valid(player) and is_instance_valid(self):
		var to_player = player.global_transform.origin - global_transform.origin
		var dist_player = to_player.length()

		if dist_player > stop_distance:
			direction = to_player.normalized()
		elif dist_player < retreat_distance:
			direction = -to_player.normalized()
		else:
			direction = Vector3.ZERO
	else:
		direction = Vector3.ZERO

func perform_dodge(enemy_direction: Vector3):
	is_dodging = true
	# Dodge perpendicular to enemy direction
	var right = enemy_direction.cross(Vector3.UP).normalized()
	dodge_direction = right if randf() > 0.5 else -right
	
	# Play dodge animation
	anim_player.play("nora-walk")
	
	# Move in dodge direction
	var dodge_tween = create_tween()
	dodge_tween.tween_property(self, "global_transform:origin", 
		global_transform.origin + dodge_direction * dodge_distance, 0.3).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.3).timeout
	is_dodging = false

func move_enemy(delta):
	if is_attacking or is_dodging:
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

	if is_waiting_for_mp:
		if not anim_player.is_playing() or anim_player.current_animation != "nora-walk":
			anim_player.play("nora-walk")
		return

	if direction.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "nora-walk":
			anim_player.play("nora-walk")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "nora-idle":
			anim_player.play("nora-idle")

func rotate_model():
	var look_target := target_enemy if is_instance_valid(target_enemy) else null
	if look_target and is_instance_valid(self):
		var to_target = (look_target.global_transform.origin - global_transform.origin).normalized()
		var target_yaw = atan2(to_target.x, to_target.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)
	elif direction.length() > 0.1 and is_instance_valid(self):
		var target_yaw = atan2(direction.x, direction.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)

func perform_ice_sword_skill(target: Node3D):
	if not is_instance_valid(target) or not is_instance_valid(self):
		return
		
	if ice_sword_on_cooldown:
		return
		
	if nora_status.mp < 10:
		return
		
	# Set cooldown immediately
	ice_sword_on_cooldown = true
	
	# Consume MP
	nora_status.consume_mana(10)
	
	# Play magic attack animation
	is_attacking = true
	current_attack_anim = "nora-magic-attack"
	anim_player.speed_scale = 1
	anim_player.play(current_attack_anim)
	
	# Wait for animation to complete
	await anim_player.animation_finished
	
	# Check if target is still valid after animation
	if not is_instance_valid(target) or not is_instance_valid(self):
		is_attacking = false
		current_attack_anim = ""
		ice_sword_on_cooldown = false
		return
	
	# Create ice sword above target
	var ice_sword = ice_sword_scene.instantiate()
	if not is_instance_valid(ice_sword):
		is_attacking = false
		current_attack_anim = ""
		ice_sword_on_cooldown = false
		return
		
	get_tree().current_scene.add_child(ice_sword)
	
	# Add collision detection
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 1, 0.5)  # Reduced size for smaller ice sword
	collision_shape.shape = shape
	ice_sword.add_child(collision_shape)
	
	# Add area for damage detection
	var damage_area = Area3D.new()
	var damage_shape = CollisionShape3D.new()
	damage_shape.shape = shape
	damage_area.add_child(damage_shape)
	ice_sword.add_child(damage_area)
	
	# Connect collision signal
	damage_area.body_entered.connect(func(body):
		if is_instance_valid(body) and (body.is_in_group("wraith") or body.is_in_group("goblin")):
			nora_damage_system.perform_skill_one(body)
			if is_instance_valid(ice_sword):
				ice_sword.queue_free()
	)
	
	# Position ice sword above target
	var target_pos = target.global_transform.origin
	ice_sword.global_transform.origin = target_pos + Vector3(0, 10, 0) # 10 units above target
	
	# Add falling movement
	var tween = create_tween()
	tween.tween_property(ice_sword, "global_transform:origin", target_pos, 0.5).set_ease(Tween.EASE_IN)
	
	# Queue free the ice sword after a delay if it hasn't hit anything
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(ice_sword):
		ice_sword.queue_free()
		
	# Reset attack state
	is_attacking = false
	current_attack_anim = ""
	
	# Wait for cooldown
	await get_tree().create_timer(ice_sword_cooldown).timeout
	ice_sword_on_cooldown = false

func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""

func _on_body_entered(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		if not detected_enemies.has(body):
			detected_enemies.append(body)
		if not is_instance_valid(target_enemy):
			target_enemy = body
	elif body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		detected_enemies.erase(body)
		if body == target_enemy:
			target_enemy = null
	elif body == player:
		player = null

func set_target(player_node: Node3D):
	player = player_node

func perform_ice_sword_rain_skill(target: Node3D):
	if not is_instance_valid(target) or not is_instance_valid(self):
		return
		
	if ice_sword_rain_on_cooldown:
		return
		
	if nora_status.mp < 20:
		return
		
	# Set cooldown immediately
	ice_sword_rain_on_cooldown = true
	
	# Consume MP
	nora_status.consume_mana(20)
	
	# Play magic attack animation
	is_attacking = true
	current_attack_anim = "nora-magic-attack"
	anim_player.speed_scale = 1
	anim_player.play(current_attack_anim)
	
	# Wait for animation to complete
	await anim_player.animation_finished
	
	# Check if target is still valid after animation
	if not is_instance_valid(target) or not is_instance_valid(self):
		is_attacking = false
		current_attack_anim = ""
		ice_sword_rain_on_cooldown = false
		return
	
	# Create blue ring effect
	var blue_ring = blue_ring_scene.instantiate()
	if not is_instance_valid(blue_ring):
		is_attacking = false
		current_attack_anim = ""
		ice_sword_rain_on_cooldown = false
		return
		
	get_tree().current_scene.add_child(blue_ring)
	blue_ring.global_transform.origin = target.global_transform.origin
	
	# Play blue ring animation
	if blue_ring.has_node("AnimationPlayer"):
		var ring_anim = blue_ring.get_node("AnimationPlayer")
		ring_anim.play("Take 01")
	
	# Create multiple ice swords in a rain pattern
	var rain_radius = 5.0  # Radius area hujan pedang
	var num_swords = 8  # Jumlah pedang yang akan jatuh
	
	for i in range(num_swords):
		# Random position within radius
		var random_offset = Vector3(
			randf_range(-rain_radius, rain_radius),
			0,
			randf_range(-rain_radius, rain_radius)
		)
		var spawn_pos = target.global_transform.origin + random_offset
		
		# Create ice sword
		var ice_sword = ice_sword_rain_scene.instantiate()
		if not is_instance_valid(ice_sword):
			continue
			
		get_tree().current_scene.add_child(ice_sword)
		
		# Add collision detection
		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.5, 1, 0.5)
		collision_shape.shape = shape
		ice_sword.add_child(collision_shape)
		
		# Add area for damage detection
		var damage_area = Area3D.new()
		var damage_shape = CollisionShape3D.new()
		damage_shape.shape = shape
		damage_area.add_child(damage_shape)
		ice_sword.add_child(damage_area)
		
		# Connect collision signal
		damage_area.body_entered.connect(func(body):
			if is_instance_valid(body) and (body.is_in_group("wraith") or body.is_in_group("goblin")):
				nora_damage_system.perform_skill_two(body)
				if is_instance_valid(ice_sword):
					ice_sword.queue_free()
		)
		
		# Position ice sword above spawn point
		ice_sword.global_transform.origin = spawn_pos + Vector3(0, 10, 0)
		
		# Add falling movement with random delay
		var tween = create_tween()
		tween.tween_property(ice_sword, "global_transform:origin", spawn_pos, 0.5).set_ease(Tween.EASE_IN)
		
		# Add cleanup timer for each sword
		var cleanup_timer = get_tree().create_timer(2.0)
		cleanup_timer.timeout.connect(func():
			if is_instance_valid(ice_sword):
				ice_sword.queue_free()
		)
		
		# Random delay between swords
		await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
	
	# Cleanup blue ring after all swords have fallen
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(blue_ring):
		blue_ring.queue_free()
	
	# Reset attack state
	is_attacking = false
	current_attack_anim = ""
	
	# Wait for cooldown
	await get_tree().create_timer(ice_sword_rain_cooldown).timeout
	ice_sword_rain_on_cooldown = false
