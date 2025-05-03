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

var joystick: Joystick
var basic_attack: TouchScreenButton
var skill_one_button: TouchScreenButton
var skill_two_button: TouchScreenButton
var skill_three_button: TouchScreenButton
var skill_four_button: TouchScreenButton
var skill_ultimate_button: TouchScreenButton
var defend_button: TouchScreenButton
var direction := Vector3.ZERO
var velocity_local := Vector3.ZERO

var anim_player: AnimationPlayer
var model: Node3D

var anim_effects: AnimationPlayer
var effect_model: Node3D

var is_attacking := false
var effect_active := false

var current_attack_anim := ""
var current_effects_anim := ""

func _ready():
	# instance joystick
	joystick = joystick_scene.instantiate()
	add_child(joystick)

	# instance basic attack button
	basic_attack = basic_attack_scene.instantiate()
	add_child(basic_attack)

	# instance skill one button
	skill_one_button = skill_one_button_scene.instantiate()
	add_child(skill_one_button)
	
	# instance skill two button
	skill_two_button = skill_two_button_scene.instantiate()
	add_child(skill_two_button)
	
	# instance skill three button
	skill_three_button = skill_three_button_scene.instantiate()
	add_child(skill_three_button)
	
	# instance skill four button
	skill_four_button = skill_four_button_scene.instantiate()
	add_child(skill_four_button)
	
	# instance skill ultimate button
	skill_ultimate_button = skill_ultimate_button_scene.instantiate()
	add_child(skill_ultimate_button)
	
	# instance defend button
	defend_button = defend_button_scene.instantiate()
	add_child(defend_button)

	basic_attack.connect("attack_pressed", Callable(self, "_on_attack_pressed"))
	defend_button.connect("defend_pressed", Callable(self, "_on_defend_pressed"))
	skill_one_button.connect("skill_one_pressed", Callable(self, "_on_skill_one_pressed"))
	skill_two_button.connect("skill_two_pressed", Callable(self, "_on_skill_two_pressed"))
	skill_three_button.connect("skill_three_pressed", Callable(self, "_on_skill_three_pressed"))
	skill_four_button.connect("skill_four_pressed", Callable(self, "_on_skill_four_pressed"))

	anim_player = $KyleModel/AnimationPlayer
	model = $KyleModel
	
	anim_effects = $PortalEffect/AnimationPlayer
	effect_model = $PortalEffect
	# atur posisi model TODO: atur tiap world
	model.position = Vector3(0, 0, -6)
	effect_model.position = Vector3(0, 0, -6)

	anim_player.connect("animation_finished", Callable(self, "_on_animation_finished"))

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

	var joystick_input = Vector2.ZERO
	if joystick:
		joystick_input = joystick.get_input_vector()

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

# ---- Fungsi event: basic attack ----
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

# ---- Fungsi event: skill one ----
func _on_skill_one_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "kyle-slash-attack"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

# ---- Fungsi event: skill two ----
func _on_skill_two_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "kyle-broken-slash"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

# ---- Fungsi event: skill three ----
func _on_skill_three_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "shadow-dash"
		anim_player.play(current_attack_anim)
		velocity = Vector3.ZERO

# ---- Fungsi event: skill four ----
func _on_skill_four_pressed():
	if not is_attacking:
		is_attacking = true
		current_attack_anim = "shadow-dash"
		current_effects_anim = "Take 001"
		effect_active = true
		anim_player.play(current_attack_anim)
		anim_effects.play(current_effects_anim)
		velocity = Vector3.ZERO

# ---- Callback selesai animasi ----
func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""
		anim_player.speed_scale = 1.0
		if effect_active:
			anim_effects.stop()
			effect_model.position = Vector3(0, 0, -6)
			current_effects_anim = ""
			effect_active = false
