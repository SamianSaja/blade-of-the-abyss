extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var support_scene = preload("res://scenes/characters/NoraPlayerSupport.tscn")
@onready var camera_scene = preload("res://scenes/Camera3D.tscn")
@onready var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")
@onready var player_status_bar_scene = preload("res://scenes/ui/PlayerStatusBar.tscn")
@onready var support_status_bar_scene = preload("res://scenes/ui/SupportStatusBar.tscn")

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


# Scene instances
var player_instance: Node3D
var support_instance: Node3D
var world_instance: Node3D
var camera_instance: Camera3D
var pause_menu_instance: CanvasLayer
var pause_menu_button: TouchScreenButton
var pause_menu_button_original_parent: Node
var player_status_bar: CanvasLayer
var player_status_bar_original_parent: Node
var support_status_bar: CanvasLayer
var support_status_bar_original_parent: Node

func _ready():
	pause_menu_button = pause_menu_button_scene.instantiate()
	add_child(pause_menu_button)
	pause_menu_button.connect("pause_menu_button_pressed", Callable(self, "toggle_pause"))

	setup_pause_menu()
	load_world("world_3")  # Default world

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

	load_player_status_bar()
	load_support_status_bar()
	spawn_player(world_name)

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

	load_player_status_bar()
	load_support_status_bar()
	spawn_player_with_custom_spawn(world_name, spawn_point_name)

	# Unpause dulu sebelum fade out
	get_tree().paused = false
	await loading.fade_out()
	loading.queue_free()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	pause_menu_instance.visible = !is_paused

	if player_instance:
		var ui_nodes := [
			player_instance.get_node_or_null("Joystick"),
			player_instance.get_node_or_null("AttackController"),
			player_instance.get_node_or_null("SkillOneButton"),
			player_instance.get_node_or_null("SkillTwoButton"),
			player_instance.get_node_or_null("SkillThreeButton"),
			player_instance.get_node_or_null("SkillFourButton"),
			player_instance.get_node_or_null("SkillUltimateButton"),
			player_instance.get_node_or_null("DefendButton")
		]
		for ui in ui_nodes:
			if ui:
				ui.visible = is_paused

	if is_paused:
		add_child(pause_menu_button)
		_restore_player_status_bar()
		_restore_support_status_bar()
	else:
		if pause_menu_button and pause_menu_instance:
			pause_menu_button.get_parent().remove_child(pause_menu_button)
		_move_player_status_bar_to_pause()
		_move_support_status_bar_to_pause()

func _restore_player_status_bar():
	if player_status_bar and player_status_bar_original_parent:
		player_status_bar.get_parent().remove_child(player_status_bar)
		player_status_bar_original_parent.add_child(player_status_bar)

		var container = player_status_bar.get_node_or_null("MarginContainer")
		if container:
			container.anchor_left = 0.02
			container.anchor_top = 0.02
			container.anchor_right = 0.02
			container.anchor_bottom = 0.02
			container.offset_left = 0
			container.offset_top = 0

			var vbox = container.get_node_or_null("VBoxContainer")
			if vbox:
				vbox.add_theme_constant_override("separation", 27)

func _move_player_status_bar_to_pause():
	if player_status_bar and pause_menu_instance:
		player_status_bar.get_parent().remove_child(player_status_bar)
		pause_menu_instance.add_child(player_status_bar)

		var container = player_status_bar.get_node_or_null("MarginContainer")
		if container:
			container.anchor_left = 0.7
			container.anchor_top = 0.2
			container.anchor_right = 0.7
			container.anchor_bottom = 0.2
			container.offset_left = 20
			container.offset_top = -40

			var vbox = container.get_node_or_null("VBoxContainer")
			if vbox:
				vbox.add_theme_constant_override("separation", 140)

func _restore_support_status_bar():
	if support_status_bar and support_status_bar_original_parent:
		support_status_bar.get_parent().remove_child(support_status_bar)
		support_status_bar_original_parent.add_child(support_status_bar)

		var container = support_status_bar.get_node_or_null("MarginContainer")
		if container:
			container.anchor_left = 0.02
			container.anchor_top = 0.02
			container.anchor_right = 0.02
			container.anchor_bottom = 0.02
			container.offset_left = 0
			container.offset_top = 118

			var vbox = container.get_node_or_null("VBoxContainer")
			if vbox:
				vbox.add_theme_constant_override("separation", 27)

func _move_support_status_bar_to_pause():
	if support_status_bar and pause_menu_instance:
		support_status_bar.get_parent().remove_child(support_status_bar)
		pause_menu_instance.add_child(support_status_bar)

		var container = support_status_bar.get_node_or_null("MarginContainer")
		if container:
			container.anchor_left = 0.7
			container.anchor_top = 0.4
			container.anchor_right = 0.7
			container.anchor_bottom = 0.4
			container.offset_left = 20
			container.offset_top = 40

			var vbox = container.get_node_or_null("VBoxContainer")
			if vbox:
				vbox.add_theme_constant_override("separation", 140)

func setup_pause_menu():
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.visible = false

	var resume_button = pause_menu_instance.get_node_or_null("VBoxContainer/ResumeContainer/ResumeButton")
	if resume_button:
		resume_button.pressed.connect(toggle_pause)

	var return_button = pause_menu_instance.get_node_or_null("ReturnMainMenu")
	if return_button:
		return_button.pressed.connect(func ():
			get_tree().paused = false
			var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
			loading.target_scene_path = "res://scenes/ui/MainMenu.tscn"
			get_tree().root.add_child(loading)
			get_tree().current_scene.queue_free()
		)

func spawn_player(world_name: String):
	if player_instance:
		player_instance.queue_free()

	player_instance = player_scene.instantiate()

	var spawn_point = world_instance.get_node_or_null("PlayerSpawn")
	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO
	add_child(player_instance)

	spawn_camera(world_name)
	spawn_world_enemy(world_name)

	if player_instance.kyle_status.has_method("set_player_status") and player_status_bar:
		player_instance.kyle_status.set_player_status(player_status_bar)
	spawn_support(world_name)

func spawn_player_with_custom_spawn(world_name: String, spawn_point_name: String):
	if player_instance:
		player_instance.queue_free()

	player_instance = player_scene.instantiate()

	var spawn_point = world_instance.get_node_or_null(spawn_point_name)
	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO

	add_child(player_instance)
	spawn_camera(world_name)
	spawn_world_enemy(world_name)

	if player_instance.kyle_status.has_method("set_player_status") and player_status_bar:
		player_instance.kyle_status.set_player_status(player_status_bar)
	
	spawn_support(world_name)

func spawn_support(world_name: String):
	if support_instance:
		support_instance.queue_free()
	
	support_instance = support_scene.instantiate()
	var spawn_point = world_instance.get_node_or_null("SupportSpawn")
	if player_instance:
		support_instance.global_transform.origin = player_instance.global_transform.origin + Vector3(0, 0, -5)
	else:
		if spawn_point:
			support_instance.global_transform.origin = spawn_point.global_transform.origin
		else:
			support_instance.global_transform.origin = Vector3.ZERO
	add_child(support_instance)
	#print("nora", support_instance.nora_status)
	if support_instance.nora_status.has_method("set_support_status") and support_status_bar:
		support_instance.nora_status.set_support_status(support_status_bar)


func spawn_camera(world_name: String):
	if camera_instance:
		camera_instance.queue_free()

	camera_instance = camera_scene.instantiate()
	camera_instance.set_script(load("res://scripts/CameraFollow.gd"))
	camera_instance.player_path = player_instance.get_path()
	if camera_limits_by_world.has(world_name):
		var limits = camera_limits_by_world[world_name]
		camera_instance.min_x = limits["min_x"]
		camera_instance.max_x = limits["max_x"]
		camera_instance.min_z = limits["min_z"]
		camera_instance.max_z = limits["max_z"]
		camera_instance.fixed_y = limits["fixed_y"]
	add_child(camera_instance)

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
				enemy_instance.set_target(player_instance.global_transform.origin)
		_:
			print("No enemies configured for world:", world_name)

func load_player_status_bar():
	if player_status_bar:
		player_status_bar.queue_free()

	player_status_bar = player_status_bar_scene.instantiate()
	add_child(player_status_bar)
	player_status_bar_original_parent = player_status_bar.get_parent()

func load_support_status_bar():
	if support_status_bar:
		support_status_bar.queue_free()

	support_status_bar = support_status_bar_scene.instantiate()
	add_child(support_status_bar)
	support_status_bar_original_parent = support_status_bar.get_parent()
