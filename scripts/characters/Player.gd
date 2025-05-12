extends CharacterBody3D

@export var speed := 7.0
@export var acceleration := 20.0
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

var current_target: Node3D = null

func _ready():
	# status and damage
	print("sword", sword_hit_box)
	add_child(kyle_status)
	add_child(kyle_damage_system)
	
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
	skill_one_button.connect("skill_one_pressed", Callable(self, "_on_skill_one_pressed"))
	skill_two_button.connect("skill_two_pressed", Callable(self, "_on_skill_two_pressed"))
	skill_three_button.connect("skill_three_pressed", Callable(self, "_on_skill_three_pressed"))
	skill_four_button.connect("skill_four_pressed", Callable(self, "_on_skill_four_pressed"))

	# Setup model & animation
	anim_player = $KyleModel/AnimationPlayer
	model = $KyleModel
	global_position = Vector3(-30, 0, -20)

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
		}
	}

	# Hide all effects initially
	for key in effect_data.keys():
		var eff = effect_data[key]
		if eff.model:
			eff.model.visible = false

func _physics_process(delta):
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
		current_attack_anim = "kyle-basic-attack"
		anim_player.speed_scale = 1.5
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

func _on_defend_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "defend"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

func _on_skill_one_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "kyle-slash-attack"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

func _on_skill_two_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "kyle-broken-slash"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

func _on_skill_three_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "shadow-dash"
		anim_player.play(current_attack_anim)
		play_effect("blue_ring")
		velocity = Vector3.ZERO

func _on_skill_four_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "kyle-searing"
		anim_player.play(current_attack_anim)
		play_effect("portal")
		velocity = Vector3.ZERO

# ---- Efek visual dinamis ----
func play_effect(effect_name: String):
	if effect_data.has(effect_name):
		var effect = effect_data[effect_name]
		current_effect_name = effect_name
		effect_active = true

		if effect.model:
			effect.model.visible = true
		if effect.anim_player and effect.anim_name:
			effect.anim_player.play(effect.anim_name)

# ---- Callback selesai animasi ----
func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""
		anim_player.speed_scale = 1.0

		if effect_active and effect_data.has(current_effect_name):
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
	kyle_status.take_damage(amount)

func _basic_attack_hit_entered(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		kyle_damage_system.perform_basic_attack(body)
