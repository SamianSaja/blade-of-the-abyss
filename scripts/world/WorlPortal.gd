# scripts/world_portal.gd
extends Area3D

@export var target_world_name: String = ""
@export var target_spawn_point_name: String = "PlayerSpawn"

func _ready():
	connect("body_entered", _on_body_entered)
	print("WorldPortal initialized - target: ", target_world_name, " spawn: ", target_spawn_point_name)

func _on_body_entered(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		print("Player entered WorldPortal - transitioning to: ", target_world_name)
		var root = get_tree().get_root()
		var game_node = root.get_node("Main")
		if game_node and game_node.world_manager and game_node.world_manager.has_method("change_world"):
			game_node.world_manager.change_world(target_world_name, target_spawn_point_name)
		else:
			print("Error: Could not access world_manager or change_world method")
