extends Node

# World registry
var worlds := {
	"altar_room": "res://scenes/world/final-area/AltarRoom.tscn",
	"world_1": "res://scenes/world/World1/World1.tscn",
	"world_2": "res://scenes/world/World2/World2.tscn",
	"world_2_2": "res://scenes/world/World2/World2-2.tscn",
	"world_3": "res://scenes/world/World3/World3.tscn",
	"world_3_2": "res://scenes/world/World3/World3-2.tscn",
	"world_3_3": "res://scenes/world/World3/World3-3.tscn",
	"world_3_final": "res://scenes/world/World3/World3-final.tscn",
}

var camera_limits_by_world = {
	# max_z = batas bawah, min_x = batas kiri, min_z = batas atas, max_x = batas kanan
	"world_1": {
		"min_x": -15.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 40.0,
		"fixed_y": 15.0
	},
	"world_2": {
		"min_x": -15.0, "max_x": 45.0,
		"min_z": -13.0, "max_z": 40.0,
		"fixed_y": 18.0
	},
	"world_2_2": {
		"min_x": -65.0, "max_x": 60.0,
		"min_z": -50.0, "max_z": 120.0,
		"fixed_y": 28.0
	},
	"world_3": {
		"min_x": -45.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 43.0,
		"fixed_y": 15.0
	},
	"world_3_2": {
		"min_x": -15.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 45.0,
		"fixed_y": 15.0
	},
	"world_3_3": {
		"min_x": -15.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 45.0,
		"fixed_y": 15.0
	},
	"world_3_final": {
		"min_x": -15.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 45.0,
		"fixed_y": 15.0
	},
	"altar_room": {
		"min_x": -15.0, "max_x": 50.0,
		"min_z": -15.0, "max_z": 45.0,
		"fixed_y": 15.0
	}
}

var world_instance: Node3D

func load_world(world_name: String):
	if world_instance:
		world_instance.queue_free()

	var world_path = worlds.get(world_name, "")
	if world_path == "":
		push_error("World '%s' not found in world registry." % world_name)
		return

	var scene = load(world_path)
	world_instance = scene.instantiate()
	add_child(world_instance)
	
	# Load status bars
	get_parent().pause_menu_manager.load_player_status_bar()
	get_parent().pause_menu_manager.load_support_status_bar()
	
	# Spawn characters
	get_parent().spawn_player(world_name)
	get_parent().play_story_if_any(world_name)

func change_world(world_name: String, spawn_point_name: String = "PlayerSpawn"):
	# Buat dan tampilkan loading screen
	var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
	get_tree().current_scene.add_child(loading)
	
	# Jangan pause dulu, fade_in butuh jalan dulu
	await loading.fade_in()
	
	# Pause game setelah fade in
	get_tree().paused = true

	# Animasi loading berjalan karena loading screen pakai pause_mode=process
	await get_tree().create_timer(2.0).timeout

	# Ganti world
	if world_instance:
		world_instance.queue_free()

	var world_path = worlds.get(world_name, "")
	if world_path == "":
		push_error("World '%s' not found in world registry." % world_name)
		get_tree().paused = false
		loading.queue_free()
		return

	var scene = load(world_path)
	world_instance = scene.instantiate()
	add_child(world_instance)

	# Load status bars
	get_parent().pause_menu_manager.load_player_status_bar()
	get_parent().pause_menu_manager.load_support_status_bar()
	
	# Spawn characters with custom spawn point
	get_parent().spawn_player_with_custom_spawn(world_name, spawn_point_name)

	# Unpause dulu sebelum fade out
	get_tree().paused = false
	await loading.fade_out()
	loading.queue_free()
	get_parent().play_story_if_any(world_name)

func spawn_world_enemy(world_name: String):
	match world_name:
		"altar_room":
			var enemy_scene = preload("res://scenes/characters/EnemyWraith.tscn")
			var enemy_instance = enemy_scene.instantiate()
			var spawn_point = world_instance.get_node_or_null("EnemyWraithSpawn")
			if spawn_point:
				enemy_instance.global_transform.origin = spawn_point.global_transform.origin
			else:
				enemy_instance.global_transform.origin = Vector3(5, 0, 5)
			add_child(enemy_instance)

			if enemy_instance.has_method("set_target"):
				enemy_instance.set_target(get_parent().player_instance.global_transform.origin)
		_:
			print("No enemies configured for world:", world_name) 