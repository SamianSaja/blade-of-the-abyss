extends CharacterBody3D

@export var speed := 7.0
@export var acceleration := 20.0
@onready var joystick_scene = preload("res://scenes/ui/Joystick.tscn")
var joystick: Joystick

var direction := Vector3.ZERO
var velocity_local := Vector3.ZERO

var anim_player: AnimationPlayer
var model: Node3D

func _ready():
	joystick = joystick_scene.instantiate()
	add_child(joystick)
	anim_player = $Kyle/AnimationPlayer
	model = $Kyle

	if joystick:
		print("Joystick ditemukan:", joystick)
	else:
		print("Joystick TIDAK ditemukan!")
	print("Player ready")

func _physics_process(delta):
	handle_input()
	move_player(delta)
	play_animation()
	rotate_model()

func handle_input():
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
	var target_velocity = direction * speed
	velocity_local = velocity_local.lerp(target_velocity, acceleration * delta)

	velocity.x = velocity_local.x
	velocity.z = velocity_local.z

	move_and_slide()

func play_animation():
	if direction.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "kyle-run-side-sword-modif":
			anim_player.play("kyle-run-side-sword-modif")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "idle":
			anim_player.play("idle")

func rotate_model():
	if direction.length() > 0.1:
		var camera_basis = get_viewport().get_camera_3d().global_transform.basis
		print(camera_basis, "camera")
		var forward = -camera_basis.z
		var right = -camera_basis.x

		var look_dir = (right * direction.x + forward * direction.z).normalized()

		var target_rotation = Quaternion(Vector3.UP, atan2(-look_dir.x, -look_dir.z))
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)
