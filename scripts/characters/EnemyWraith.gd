extends CharacterBody3D

@export var speed := 2.0
@export var acceleration := 5.0

@onready var anim_player: AnimationPlayer = $WraithModel/AnimationPlayer
@onready var model: Node3D = $WraithModel
@onready var detection_area: Area3D = $DetectionArea

var velocity_local := Vector3.ZERO
var direction := Vector3.ZERO
var is_attacking := false
var current_attack_anim := ""

var player: Node3D = null


func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	handle_ai()
	move_enemy(delta)
	play_animation()
	rotate_model()

func handle_ai():
	if is_instance_valid(player) and not is_attacking:
		print("Player Pos:", player.global_transform.origin)
		var to_player = player.global_transform.origin - global_transform.origin
		print("Distance to player:", to_player.length())
		if to_player.length() < 1:
			direction = Vector3.ZERO
			start_attack("wraith-magic-attack")
		else:
			direction = to_player.normalized()
	else:
		direction = Vector3.ZERO


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
	if direction.length() > 0.1:
		var target_rotation = Quaternion(Vector3.UP, atan2(direction.x, direction.z))
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)

func start_attack(anim_name: String):
	is_attacking = true
	current_attack_anim = anim_name
	anim_player.play(current_attack_anim)

func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		print("player terdeteksi")
		player = body

func _on_body_exited(body: Node):
	if body == player:
		player = null
