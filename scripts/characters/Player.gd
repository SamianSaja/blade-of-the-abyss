extends CharacterBody3D

@export var speed := 5.0
@export var acceleration := 10.0

var direction := Vector3.ZERO
var velocity_local := Vector3.ZERO

var anim_player: AnimationPlayer
var model: Node3D

func _ready():
	anim_player = $Kyle/AnimationPlayer
	model = $Kyle
	print("Player ready")

func _physics_process(delta):
	handle_input()
	move_player(delta)
	play_animation()
	rotate_model()

func handle_input():
	direction = Vector3.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	direction = direction.normalized()
	
	if direction.length() > 0:
		print("Direction input: ", direction)

func move_player(delta):
	var target_velocity = direction * speed
	velocity_local = velocity_local.lerp(target_velocity, acceleration * delta)

	# Print hasil interpolasi velocity
	print("Velocity local: ", velocity_local)

	velocity.x = velocity_local.x
	velocity.z = velocity_local.z

	move_and_slide()

func play_animation():
	if direction.length() > 0.1:
		if not anim_player.is_playing() or anim_player.current_animation != "kyle-run-side-sword-modif":
			anim_player.play("kyle-run-side-sword-modif")
			print("Playing Walk animation")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "idle":
			anim_player.play("idle")
			print("Playing Idle animation")

func rotate_model():
	if direction.length() > 0.1:
		var camera_basis = $Camera3D.global_transform.basis
		var forward = -camera_basis.z
		var right = -camera_basis.x

		var look_dir = (right * direction.x + forward * direction.z).normalized()

		var target_rotation = Quaternion(Vector3.UP, atan2(-look_dir.x, -look_dir.z))
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)
