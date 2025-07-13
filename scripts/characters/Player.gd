extends CharacterBody3D

#@export var speed := 7.0
#@export var acceleration := 20.0
@onready var joystick_scene = preload("res://scenes/ui/Joystick.tscn")
@onready var basic_attack_scene = preload("res://scenes/ui/AttackController.tscn")
@onready var skill_one_button_scene = preload("res://scenes/ui/SkillOneButton.tscn")
@onready var skill_two_button_scene = preload("res://scenes/ui/SkillTwoButton.tscn")
@onready var skill_three_button_scene = preload("res://scenes/ui/SkillThreeButton.tscn")
@onready var skill_four_button_scene = preload("res://scenes/ui/SkillFourButton.tscn")
@onready var skill_ultimate_button_scene = preload("res://scenes/ui/SkillUltimateButton.tscn")
@onready var defend_button_scene = preload("res://scenes/ui/DefendButton.tscn")
#@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")

# status and damage
@onready var kyle_status = preload("res://scripts/data/Kyle/KyleStatus.gd").new()
@onready var kyle_damage_system = preload("res://scripts/data/Kyle/KyleDamage.gd").new()
@onready var sword_hit_box: Area3D = $KyleModel/Armature/Skeleton3D/Father_Sword/SwordHitBox
@onready var detection_area: Area3D = $DetectionArea
@onready var sword_attachment: BoneAttachment3D = $KyleModel/Armature/Skeleton3D/Father_Sword
@onready var ultimate_purple_light: OmniLight3D = $KyleModel/UltimatePurpleLight


var joystick: Joystick
var basic_attack: TouchScreenButton
var skill_one_button: TouchScreenButton
var skill_two_button: TouchScreenButton
var skill_three_button: TouchScreenButton
var skill_four_button: TouchScreenButton
var skill_ultimate_button: TouchScreenButton
var defend_button: TouchScreenButton
#var player_status_bar: CanvasLayer
#var pause_menu_button: TouchScreenButton

var direction := Vector3.ZERO
var velocity_local := Vector3.ZERO

var anim_player: AnimationPlayer
var model: Node3D

var is_attacking := false
var current_attack_anim := ""

# Multi-effect support
var current_effect_name := ""
var effect_active := false
var effect_data := {}  # name -> {model, anim_player, anim_name}
var active_buff_effects := []  # List of active buff effects

var current_target: Node3D = null
var current_attack_type: String = "none"

# Sword material for ultimate effect
var original_sword_material: Material
var ultimate_sword_material: Material

# Ultimate skill variables
var ultimate_active := false
var ultimate_timer := 0.0
var ultimate_duration := 30.0  # 30 detik
var ultimate_heal_amount := 20  # HP yang ditambahkan per hit

func _ready():
	# status and damage
	add_child(kyle_status)
	add_child(kyle_damage_system)
	kyle_damage_system.set_player_status(kyle_status)
	
	# instance joystick
	joystick = joystick_scene.instantiate()
	add_child(joystick)

	# instance all buttons
	basic_attack = basic_attack_scene.instantiate()
	add_child(basic_attack)

	skill_one_button = skill_one_button_scene.instantiate()
	add_child(skill_one_button)

	skill_two_button = skill_two_button_scene.instantiate()
	add_child(skill_two_button)

	skill_three_button = skill_three_button_scene.instantiate()
	add_child(skill_three_button)

	skill_four_button = skill_four_button_scene.instantiate()
	add_child(skill_four_button)

	skill_ultimate_button = skill_ultimate_button_scene.instantiate()
	add_child(skill_ultimate_button)

	defend_button = defend_button_scene.instantiate()
	add_child(defend_button)
	
	#pause_menu_button = pause_menu_button_scene.instantiate()
	#add_child(pause_menu_button)

	# Connect
	basic_attack.connect("attack_pressed", Callable(self, "_on_attack_pressed"))
	defend_button.connect("defend_pressed", Callable(self, "_on_defend_pressed"))
	defend_button.connect("defend_held", Callable(self, "_on_defend_pressed"))
	skill_one_button.connect("skill_one_pressed", Callable(self, "_on_skill_one_pressed"))
	skill_two_button.connect("skill_two_pressed", Callable(self, "_on_skill_two_pressed"))
	skill_three_button.connect("skill_three_pressed", Callable(self, "_on_skill_three_pressed"))
	skill_four_button.connect("skill_four_pressed", Callable(self, "_on_skill_four_pressed"))
	skill_ultimate_button.connect("skill_ultimate_pressed", Callable(self, "_on_skill_ultimate_pressed"))

	# Setup model & animation
	anim_player = $KyleModel/AnimationPlayer
	model = $KyleModel
	#global_position = Vector3(-30, 0, -20)

	anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

	add_to_group("player")
	sword_hit_box.body_entered.connect(_basic_attack_hit_entered)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


	# Setup effect registry
	effect_data = {
		"blue_ring": {
			"model": $KyleModel/BlueRingEffect,
			"anim_player": $KyleModel/BlueRingEffect/AnimationPlayer,
			"anim_name": "Take 01"
		},
		"portal": {
			"model": $KyleModel/PortalEffect,
			"anim_player": $KyleModel/PortalEffect/AnimationPlayer,
			"anim_name": "Take 001"
		},
		"speed_buff": {
			"model": $KyleModel/GreenRingEffect,
			"anim_player": $KyleModel/GreenRingEffect/AnimationPlayer,
			"anim_name": "Take 01"
		},
		"defense_buff": {
			"model": $KyleModel/YellowRingEffect,
			"anim_player": $KyleModel/YellowRingEffect/AnimationPlayer,
			"anim_name": "Take 01"
		},
		"ultimate_effect": {
			"model": $KyleModel/RedRingEffect,
			"anim_player": $KyleModel/RedRingEffect/AnimationPlayer,
			"anim_name": "CircleAction"
		}
	}

	# Hide all effects initially
	for key in effect_data.keys():
		var eff = effect_data[key]
		if eff.model:
			eff.model.visible = false
	
	# Setup sword materials for ultimate effect
	# For now, we'll create a simple purple material for the ultimate effect
	ultimate_sword_material = StandardMaterial3D.new()
	if ultimate_sword_material:
		ultimate_sword_material.albedo_color = Color(0.8, 0.2, 1.0, 1.0)  # Purple color
		ultimate_sword_material.emission_enabled = true
		ultimate_sword_material.emission = Color(0.8, 0.2, 1.0, 1.0)
		ultimate_sword_material.emission_energy = 2.0
		print("Ultimate sword material created successfully")
	else:
		print("Failed to create ultimate sword material")

#func _process(delta):
	#if current_attack_type == "skill-four":
		#kyle_damage_system.perform_skill_four()

func _physics_process(delta):
	# Update buffs
	kyle_status.update_buffs(delta)
	
	# Update ultimate skill timer
	if ultimate_active:
		ultimate_timer -= delta
		if ultimate_timer <= 0:
			deactivate_ultimate_skill()
	
	# Hide buff effects when buffs expire
	if not kyle_status.is_speed_buffed() and "speed_buff" in active_buff_effects:
		stop_effect("speed_buff")
		active_buff_effects.erase("speed_buff")
	
	if not kyle_status.is_defense_buffed() and "defense_buff" in active_buff_effects:
		stop_effect("defense_buff")
		active_buff_effects.erase("defense_buff")
	
	handle_input()
	move_player(delta)
	play_animation()
	rotate_model()

func handle_input():
	if is_attacking:
		direction = Vector3.ZERO
		return

	direction = Vector3.ZERO
	var joystick_input = joystick.get_input_vector() if joystick else Vector2.ZERO

	if joystick_input.length() > 0.1:
		direction.x = joystick_input.x
		direction.z = joystick_input.y
	else:
		direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		direction.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	direction = direction.normalized()

func move_player(delta):
	if is_attacking:
		return

	var target_velocity = direction * kyle_status.speed
	velocity_local = velocity_local.lerp(target_velocity, kyle_status.acceleration * delta)
	velocity.x = velocity_local.x
	velocity.z = velocity_local.z
	move_and_slide()

func play_animation():
	if is_attacking:
		if not anim_player.is_playing() or anim_player.current_animation != current_attack_anim:
			anim_player.play(current_attack_anim)
		return

	if direction.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "kyle-run-side-sword-modif":
			anim_player.play("kyle-run-side-sword-modif")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "idle":
			anim_player.play("idle")

func rotate_model():
	if direction.length() > 0.1:
		var camera_basis = get_viewport().get_camera_3d().global_transform.basis
		var forward = -camera_basis.z
		var right = -camera_basis.x
		var look_dir = (right * direction.x + forward * direction.z).normalized()
		var target_rotation = Quaternion(Vector3.UP, atan2(-look_dir.x, -look_dir.z))
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)

# ---- Basic attack ----
func _on_attack_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_type = "basic-attack"
		current_attack_anim = "kyle-basic-attack"
		anim_player.speed_scale = 1.5
		anim_player.play(current_attack_anim)
		await get_tree().create_timer(0.1).timeout
		$AttackEffectSound.play()
		velocity = Vector3.ZERO

func _on_defend_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_type = "defend"
		current_attack_anim = "defend"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

func _on_skill_one_pressed():
	if not is_attacking:
		# Check if player has enough TP
		var required_tp = 20
		if kyle_status.tp < required_tp:
			print("Not enough TP for Skill 1! Need: ", required_tp, " TP")
			return
		
		# Consume TP
		kyle_status.consume_tp(required_tp)
		
		is_attacking = true
		current_attack_type = "skill-one"
		current_attack_anim = "kyle-slash-attack"
		anim_player.speed_scale = 1.5
		anim_player.play(current_attack_anim)
		await get_tree().create_timer(0.5).timeout
		$SkillOneEffectSound.play()
		velocity = Vector3.ZERO

func _on_skill_two_pressed():
	if not is_attacking:
		# Check if player has enough TP
		var required_tp = 30
		if kyle_status.tp < required_tp:
			print("Not enough TP for Skill 2! Need: ", required_tp, " TP")
			return
		
		# Consume TP
		kyle_status.consume_tp(required_tp)
		
		is_attacking = true
		current_attack_type = "skill-two"
		current_attack_anim = "kyle-broken-slash"
		anim_player.play(current_attack_anim)
		await get_tree().create_timer(1.5).timeout
		$SkillTwoEffectSound.play()
		velocity = Vector3.ZERO

func _on_skill_three_pressed():
	if not is_attacking:
		# Check if player has enough MP
		var required_mp = 40
		if kyle_status.mp < required_mp:
			print("Not enough MP for Skill 3! Need: ", required_mp, " MP")
			return
		
		# Consume MP
		kyle_status.consume_mana(required_mp)
		
		is_attacking = true
		current_attack_type = "skill-three"
		current_attack_anim = "shadow-dash"
		anim_player.play(current_attack_anim)
		play_effect("blue_ring")
		
		# Apply speed buff
		kyle_status.apply_speed_buff()
		
		# Play speed buff sound
		if has_node("SpeedBuffSound"):
			$SpeedBuffSound.play()
		
		# Show speed buff effect after a short delay
		await get_tree().create_timer(0.5).timeout
		if "speed_buff" not in active_buff_effects:
			play_effect("speed_buff")
			active_buff_effects.append("speed_buff")
		
		velocity = Vector3.ZERO

func _on_skill_four_pressed():
	if not is_attacking:
		# Check if player has enough MP
		var required_mp = 50
		if kyle_status.mp < required_mp:
			print("Not enough MP for Skill 4! Need: ", required_mp, " MP")
			return
		
		# Consume MP
		kyle_status.consume_mana(required_mp)
		
		is_attacking = true
		current_attack_type = "skill-four"
		current_attack_anim = "kyle-searing"
		anim_player.play(current_attack_anim)
		play_effect("portal")
		
		# Apply defense buff
		kyle_status.apply_defense_buff()
		
		# Play defense buff sound
		if has_node("DefenseBuffSound"):
			$DefenseBuffSound.play()
		
		# Show defense buff effect
		await get_tree().create_timer(0.5).timeout
		if "defense_buff" not in active_buff_effects:
			play_effect("defense_buff")
			active_buff_effects.append("defense_buff")
		
		velocity = Vector3.ZERO

func _on_skill_ultimate_pressed():
	if not ultimate_active:
		# Check if player has enough mana (50% of max MP)
		var required_mana = kyle_status.max_mp * 0.5
		if kyle_status.mp < required_mana:
			print("Not enough mana for Mode Abyss! Need: ", required_mana, " MP")
			return
		
		# Consume 50% of max MP
		kyle_status.consume_mana(required_mana)
		
		# Activate ultimate skill for 30 seconds
		ultimate_active = true
		ultimate_timer = ultimate_duration
		
		# Apply ultimate sword effect
		apply_ultimate_sword_effect()
		
		# Activate purple light
		activate_ultimate_light()
		
		# Play ultimate effect (Red ring behind Kyle's back)
		play_effect("ultimate_effect")
		
		print("Mode Abyss activated for 30 seconds! Consumed ", required_mana, " MP")

# ---- Efek visual dinamis ----
func play_effect(effect_name: String):
	if effect_data.has(effect_name):
		var effect = effect_data[effect_name]
		current_effect_name = effect_name
		effect_active = true

		if effect.model:
			effect.model.visible = true
		if effect.anim_player and effect.anim_name:
			# For ultimate effect, make it loop
			if effect_name == "ultimate_effect":
				effect.anim_player.play(effect.anim_name)
				effect.anim_player.get_animation_library("").get_animation(effect.anim_name).loop_mode = Animation.LOOP_LINEAR
			else:
				effect.anim_player.play(effect.anim_name)

func stop_effect(effect_name: String):
	if effect_data.has(effect_name):
		var effect = effect_data[effect_name]
		if effect.anim_player:
			effect.anim_player.stop()
		if effect.model:
			effect.model.visible = false

func apply_ultimate_sword_effect():
	if sword_attachment and ultimate_sword_material:
		# Find the first MeshInstance3D child of the bone attachment
		for child in sword_attachment.get_children():
			if child is MeshInstance3D:
				child.mesh.surface_set_material(0, ultimate_sword_material)
				print("Ultimate sword effect applied!")
				return
		print("No mesh found in sword attachment for ultimate effect")

func restore_sword_material():
	if sword_attachment:
		# Find the first MeshInstance3D child of the bone attachment
		for child in sword_attachment.get_children():
			if child is MeshInstance3D:
				# Reset to default material (index 0)
				child.mesh.surface_set_material(0, null)
				print("Sword material restored!")
				return
		print("No mesh found in sword attachment to restore")

func activate_ultimate_light():
	if ultimate_purple_light:
		ultimate_purple_light.light_energy = 8.0
		print("Ultimate purple light activated!")

func deactivate_ultimate_light():
	if ultimate_purple_light:
		ultimate_purple_light.light_energy = 0.0
		print("Ultimate purple light deactivated!")

func deactivate_ultimate_skill():
	ultimate_active = false
	ultimate_timer = 0.0
	restore_sword_material()
	deactivate_ultimate_light()
	stop_effect("ultimate_effect")
	print("Mode Abyss deactivated!")

# ---- Callback selesai animasi ----
func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		# Stop skill effects based on attack type
		var attack_type = current_attack_type
		
		is_attacking = false
		current_attack_type = "none"
		current_attack_anim = ""
		anim_player.speed_scale = 1.0

		# Stop skill effects but keep buff effects and ultimate effect
		if attack_type == "skill-three":
			stop_effect("blue_ring")
		elif attack_type == "skill-four":
			stop_effect("portal")
		# Note: Ultimate effect and buff effects are not stopped here
		# Ultimate effect runs for 30 seconds, buff effects are managed separately
		elif attack_type != "skill-ultimate":  # Don't stop ultimate effect
			# For other skills, stop current effect only if it's not ultimate
			if effect_active and effect_data.has(current_effect_name) and current_effect_name != "ultimate_effect":
				var effect = effect_data[current_effect_name]
				if effect.anim_player:
					effect.anim_player.stop()
				if effect.model:
					effect.model.visible = false
				effect_active = false
				current_effect_name = ""

func _on_body_entered(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		current_target = body

func _on_body_exited(body: Node):
	if body == current_target:
		current_target = null

func take_damage(amount: int):
	if current_attack_type == "defend":
		amount = amount * 0.2  # kurangi damage jika defend
	kyle_status.take_damage(amount)

# Buff status functions for UI
func get_speed_buff_remaining() -> float:
	return kyle_status.get_speed_buff_remaining()

func get_defense_buff_remaining() -> float:
	return kyle_status.get_defense_buff_remaining()

func is_speed_buffed() -> bool:
	return kyle_status.is_speed_buffed()

func is_defense_buffed() -> bool:
	return kyle_status.is_defense_buffed()

# Ultimate status functions for UI
func is_ultimate_active() -> bool:
	return ultimate_active

func get_ultimate_remaining() -> float:
	return ultimate_timer

func _basic_attack_hit_entered(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		match current_attack_type:
			"basic-attack":
				kyle_damage_system.perform_basic_attack(body)
				# Check if ultimate is active for healing (Mode Abyss)
				if ultimate_active:
					kyle_status.heal(ultimate_heal_amount)
					print("Mode Abyss healing applied! +", ultimate_heal_amount, " HP")
			"skill-one":
				kyle_damage_system.perform_skill_one(body)
			"skill-ultimate":
				kyle_damage_system.perform_ultimate_attack(body)
				#kyle_status.consume_mana(30)
				# print("No attack type matched or idle")
