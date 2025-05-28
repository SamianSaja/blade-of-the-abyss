# scripts/world_portal.gd
extends Area3D

@export var target_world_name: String = ""
@export var target_spawn_point_name: String = "PlayerSpawn"

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		var root = get_tree().get_root()
		var game_node = root.get_node("Main")
		if game_node and game_node.has_method("change_world"):
			game_node.change_world(target_world_name, target_spawn_point_name)
