extends Node3D

@export var delay_before_spawn := 2.0
@export var duration := 2.0
@export var damage := 20

@onready var tornado_effect = $TornadoEffect
@onready var hit_area: Area3D = $HitArea
@onready var telegraph = $TelegraphDecal
@onready var anim_player: AnimationPlayer = $TornadoEffect/AnimationPlayer

var player: Node3D
var is_moving = false
var move_direction = Vector3.ZERO
@export var move_speed := 10.0

func _ready():
	hit_area.body_entered.connect(_on_HitArea_body_entered)

func _physics_process(delta):
	if is_moving:
		global_translate(move_direction * move_speed * delta)

func set_random_movement():
	is_moving = true
	var angle = randf_range(0, PI * 2)
	move_direction = Vector3(cos(angle), 0, sin(angle)).normalized()

func start_skill(target_position: Vector3):
	global_transform.origin = target_position
	tornado_effect.visible = false
	hit_area.monitoring = false
	telegraph.visible = true

	await get_tree().create_timer(delay_before_spawn).timeout

	telegraph.visible = false
	tornado_effect.visible = true
	hit_area.monitoring = true

	# 🔥 Mainkan animasi muncul
	if anim_player.has_animation("Animation"):
		anim_player.speed_scale = 10
		var anim = anim_player.get_animation("Animation")
		anim.loop = true  # ✅ This is correct
		anim_player.play("Animation")


	await get_tree().create_timer(duration).timeout
	queue_free()

func start_skill_2(target_position: Vector3):
	global_transform.origin = target_position
	telegraph.visible = false
	tornado_effect.visible = true
	hit_area.monitoring = true

	# 🔥 Mainkan animasi muncul
	if anim_player.has_animation("Animation"):
		anim_player.speed_scale = 5
		var anim = anim_player.get_animation("Animation")
		anim.loop = true  # ✅ This is correct
		anim_player.play("Animation")


	await get_tree().create_timer(duration).timeout
	queue_free()

func _on_HitArea_body_entered(body):
	if body.is_in_group("player"):
		body.call_deferred("take_damage", damage)
