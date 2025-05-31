extends CharacterBody3D

@export var speed := 2.5
@export var attack_range := 2.0
@export var acceleration := 10.0
@export var max_health := 100
@export var damage := 10

@onready var anim_player: AnimationPlayer = $GoblinModel/AnimationPlayer
@onready var detection_area: Area3D = $DetectionArea
@onready var health_bar: Control = $HealthBar
@onready var camera: Camera3D = null

@onready var status = preload("res://scripts/data/goblin/GoblinStatus.gd").new()

var current_health := 100
var is_attacking := false
var player: Node3D = null
var support: Node3D = null
var target: Node3D = null

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	current_health = max_health
	anim_player.animation_finished.connect(_on_animation_finished)
	add_to_group("goblin")

func _process(delta):
	camera = get_viewport().get_camera_3d()
	if health_bar and camera:
		var head_offset = Vector3(-1.5, 2.5, 0)
		var world_pos = global_transform.origin + head_offset
		var screen_pos = camera.unproject_position(world_pos)
		health_bar.global_position = screen_pos
		status.set_status(health_bar)

func _physics_process(delta):
	if status.hp <= 0:
		return

	update_target()

	if is_instance_valid(target):
		var to_target = target.global_transform.origin - global_transform.origin
		var distance = to_target.length()

		if distance <= attack_range:
			velocity = Vector3.ZERO
			if not is_attacking:
				start_attack()
		else:
			move_towards_player(delta, to_target)
	else:
		velocity = Vector3.ZERO
		anim_player.play("monster-walk")

	move_and_slide()

func update_target():
	if is_instance_valid(player) and is_instance_valid(support):
		var dist_player = global_transform.origin.distance_to(player.global_transform.origin)
		var dist_support = global_transform.origin.distance_to(support.global_transform.origin)
		target = player if dist_player <= dist_support else support
	elif is_instance_valid(player):
		target = player
	elif is_instance_valid(support):
		target = support
	else:
		target = null

func move_towards_player(delta, to_target: Vector3):
	if is_attacking:
		return

	var dir = to_target.normalized()
	velocity = velocity.lerp(dir * speed, acceleration * delta)

	if dir.length() > 0.1:
		rotate_towards(dir)
		anim_player.play("monster-walk")

func rotate_towards(dir: Vector3):
	var target_yaw = atan2(dir.x, dir.z)
	var target_rot = Quaternion(Vector3.UP, target_yaw)
	rotation = rotation.slerp(target_rot.get_euler(), 0.2)

func start_attack():
	is_attacking = true
	anim_player.speed_scale = 0.5	
	anim_player.play("monster-attack")
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(target):
			if target == support:
				target.nora_status.call_deferred("take_damage", damage)
			else:
				target.call_deferred("take_damage", damage)
	$AttackSound.play()

func _on_animation_finished(anim_name: String):
	is_attacking = false

func take_damage(amount: int):
	status.take_damage(amount)
	if status.is_dead():
		die()

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		player = body
	elif body.is_in_group("support"):
		support = body

func _on_body_exited(body: Node):
	if body == player:
		player = null
	elif body == support:
		support = null

func die():
	anim_player.play("monster-die")
	await get_tree().create_timer(5).timeout
	queue_free()
	if is_instance_valid(player):
		player.kyle_status.call_deferred("gain_exp", 10)
	if is_instance_valid(support):
		support.nora_status.call_deferred("gain_exp", 10)
