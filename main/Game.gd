extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var world_scene = preload("res://scenes/world/final-area/AltarRoom.tscn")

var player_instance: Node3D
var world_instance: Node3D

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

	var spawn_point = world_instance.get_node_or_null("PlayerSpawn")
	player_instance = player_scene.instantiate()

	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO

	add_child(player_instance)
