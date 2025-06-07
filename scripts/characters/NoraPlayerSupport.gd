extends CharacterBody3D

@export var speed := 3.0
@export var acceleration := 20.0
@export var attack_range := 10.0
@export var stop_distance := 2.5  # Jarak aman saat mengikuti player
@export var retreat_distance := 1.0  # Terlalu dekat → mundur

@onready var anim_player: AnimationPlayer = $NoraModel/AnimationPlayer
@onready var model: Node3D = $NoraModel
@onready var detection_area: Area3D = $DetectionAreaNora

@onready var nora_status = preload("res://scripts/data/Nora/NoraStatus.gd").new()
@onready var nora_damage_system = preload("res://scripts/data/Nora/NoraDamage.gd").new()

var velocity_local := Vector3.ZERO
var direction := Vector3.ZERO
var is_attacking := false
var current_attack_anim := ""

var player: Node3D = null
var target_enemy: Node3D = null


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
	var target: Node3D = null

	# Prioritaskan enemy jika masih dalam jarak
	if is_instance_valid(target_enemy):
		var to_enemy = target_enemy.global_transform.origin - global_transform.origin
		var dist_enemy = to_enemy.length()

		if dist_enemy <= attack_range and not is_attacking:
			direction = Vector3.ZERO
			start_attack("nora-magic-attack")
			return
		elif dist_enemy > attack_range + 2.0:
			# Enemy terlalu jauh, hapus target
			target_enemy = null
		else:
			# Dekati enemy jika belum cukup dekat
			direction = to_enemy.normalized()
			return

	# Jika tidak ada enemy, dekati player
	if is_instance_valid(player) and not is_attacking:
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
		if not anim_player.is_playing() or anim_player.current_animation != "nora-walk":
			anim_player.play("nora-walk")
	else:
		if not anim_player.is_playing() or anim_player.current_animation != "nora-idle":
			anim_player.play("nora-idle")

func rotate_model():
	var look_target := target_enemy if is_attacking and is_instance_valid(target_enemy) else null
	if look_target:
		var to_target = (look_target.global_transform.origin - global_transform.origin).normalized()
		var target_yaw = atan2(to_target.x, to_target.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)
	elif direction.length() > 0.1:
		var target_yaw = atan2(direction.x, direction.z)
		var target_rotation = Quaternion(Vector3.UP, target_yaw)
		model.rotation = model.rotation.slerp(target_rotation.get_euler(), 0.2)


func start_attack(anim_name: String):
	is_attacking = true
	current_attack_anim = anim_name
	anim_player.speed_scale = 1
	anim_player.play(current_attack_anim)

func _on_animation_finished(anim_name: String):
	if anim_name == current_attack_anim:
		is_attacking = false
		current_attack_anim = ""

func _on_body_entered(body: Node):
	if body.is_in_group("wraith") or body.is_in_group("goblin"):
		target_enemy = body
	elif body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node):
	if body == target_enemy:
		target_enemy = null
	elif body == player:
		player = null

func set_target(player_node: Node3D):
	player = player_node
