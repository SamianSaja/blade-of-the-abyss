extends CharacterBody3D

@export var speed := 3.0
@export var acceleration := 20.0
@export var attack_range := 10.0  # Jarak maksimum untuk menyerang
@export var stop_distance := 8.0  # Jarak minimum sebelum musuh mulai mundur

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
		var to_player = player.global_transform.origin - global_transform.origin
		var distance = to_player.length()

		if distance <= attack_range and distance >= stop_distance:
			# Dalam jarak serang → diam & serang
			direction = Vector3.ZERO
			start_attack("wraith-magic-attack")
		elif distance < stop_distance:
			# Terlalu dekat → mundur menjauh
			direction = -to_player.normalized()
		else:
			# Terlalu jauh → dekati pemain
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
	if is_attacking and is_instance_valid(player):
		# Saat menyerang, selalu menghadap ke pemain
		var to_player = (player.global_transform.origin - global_transform.origin).normalized()
		var target_yaw = atan2(to_player.x, to_player.z)
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
