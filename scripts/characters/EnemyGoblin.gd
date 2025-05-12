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

# status and damage
@onready var status = preload("res://scripts/data/goblin/GoblinStatus.gd").new()

var current_health := 100
var is_attacking := false
var player: Node3D = null

func _ready():
	camera = get_viewport().get_camera_3d()
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	current_health = max_health
	anim_player.animation_finished.connect(_on_animation_finished)
	add_to_group("goblin")

func _process(delta):
	if health_bar and camera:
		var head_offset = Vector3(-1.5, 2.5, 0) # Tinggi di atas model
		var world_pos = global_transform.origin + head_offset
		var screen_pos = camera.unproject_position(world_pos)
		health_bar.global_position = screen_pos
		status.set_status(health_bar)
		#wraith_damage_system.set_enemy_status(health_bar)

func _physics_process(delta):
	if status.hp <= 0:
		return

	if is_instance_valid(player):
		var to_player = player.global_transform.origin - global_transform.origin
		var distance = to_player.length()

		if distance <= attack_range:
			velocity = Vector3.ZERO
			if not is_attacking:
				start_attack()
		else:
			move_towards_player(delta, to_player)
	else:
		velocity = Vector3.ZERO
		anim_player.play("monster-walk")

	move_and_slide()

func move_towards_player(delta, to_player: Vector3):
	if is_attacking:
		return

	var dir = to_player.normalized()
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
	anim_player.play("monster-attack")

func _on_animation_finished(anim_name: String):
	if anim_name == "monster-attack":
		if is_instance_valid(player):
			player.call_deferred("take_damage", damage)
		is_attacking = false

func take_damage(amount: int):
	status.take_damage(amount)
	if status.is_dead():
		die()

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node):
	if body == player:
		player = null

func die():
	anim_player.play("monster-die")
	await get_tree().create_timer(5).timeout
	queue_free()
