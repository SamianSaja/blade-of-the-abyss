extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var world_scene = preload("res://scenes/world/final-area/AltarRoom.tscn")
@onready var camera_scene = preload("res://scenes/Camera3D.tscn")
@onready var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")

var player_instance: Node3D
var world_instance: Node3D
var camera_instance: Camera3D
var pause_menu_instance: CanvasLayer
var pause_menu_button: TouchScreenButton


func _ready():
	# pause menu button action
	pause_menu_button = pause_menu_button_scene.instantiate()
	add_child(pause_menu_button)
	pause_menu_button.connect("pause_menu_button_pressed", Callable(self, "toggle_pause"))

	
	load_world()
	setup_pause_menu()

func load_world():
	if world_instance:
		world_instance.queue_free()

	world_instance = world_scene.instantiate()
	add_child(world_instance)

	spawn_player()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	pause_menu_instance.visible = !is_paused

func setup_pause_menu():
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.visible = false

	# Hubungkan tombol resume
	var resume_button = pause_menu_instance.get_node_or_null("VBoxContainer/ResumeContainer/ResumeButton")
	if resume_button:
		resume_button.pressed.connect(toggle_pause)
	else:
		print("❌ ResumeButton not found!")

	var return_button = pause_menu_instance.get_node_or_null("ReturnMainMenu")
	if return_button:
		return_button.pressed.connect(func ():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://MainMenu.tscn")
		)
	else:
		print("❌ ReturnMainMenu button not found!")



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
