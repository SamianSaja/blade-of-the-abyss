extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var world_scene = preload("res://scenes/world/final-area/AltarRoom.tscn")
@onready var camera_scene = preload("res://scenes/Camera3D.tscn") # Camera3D buatanmu, pisah dari Player

var player_instance: Node3D
var world_instance: Node3D
var camera_instance: Camera3D

func _ready():
	load_world()

func load_world():
	if world_instance:
		world_instance.queue_free()

	world_instance = world_scene.instantiate()
	add_child(world_instance)

	spawn_player()

func spawn_player():
	if player_instance:
		player_instance.queue_free()

	player_instance = player_scene.instantiate()

	var spawn_point = world_instance.get_node_or_null("PlayerSpawn")
	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO

	add_child(player_instance)

	# Spawn camera setelah player
	spawn_camera()
	spawn_enemy()

func spawn_enemy():
	var enemy_scene = preload("res://scenes/characters/EnemyWraith.tscn")
	var enemy_instance = enemy_scene.instantiate()

	var spawn_point = world_instance.get_node_or_null("EnemyWraithSpawn")
	if spawn_point:
		enemy_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		enemy_instance.global_transform.origin = Vector3(5, 0, 5)

	add_child(enemy_instance)

	# Set player as target (contoh)
	if enemy_instance.has_method("set_target"):
		enemy_instance.set_target(player_instance.global_transform.origin)


func spawn_camera():
	if camera_instance:
		camera_instance.queue_free()
	
	# camera configuration
	camera_instance = camera_scene.instantiate()
	camera_instance.set_script(load("res://scripts/CameraFollow.gd"))
	camera_instance.player_path = player_instance.get_path()

	add_child(camera_instance)
