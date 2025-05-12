extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var world_scene = preload("res://scenes/world/final-area/AltarRoom.tscn")
@onready var camera_scene = preload("res://scenes/Camera3D.tscn")
@onready var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")
@onready var player_status_bar_scene = preload("res://scenes/ui/PlayerStatusBar.tscn")

var player_instance: Node3D
var world_instance: Node3D
var camera_instance: Camera3D
var pause_menu_instance: CanvasLayer
var pause_menu_button: TouchScreenButton
var pause_menu_button_original_parent: Node
var player_status_bar: CanvasLayer
var player_status_bar_original_parent: Node


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
	load_player_status_bar()
	spawn_player()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	pause_menu_instance.visible = !is_paused

	var player = get_node_or_null("Player")
	if player:
		var ui_nodes := [
			player.get_node_or_null("Joystick"),
			player.get_node_or_null("AttackController"),
			player.get_node_or_null("SkillOneButton"),
			player.get_node_or_null("SkillTwoButton"),
			player.get_node_or_null("SkillThreeButton"),
			player.get_node_or_null("SkillFourButton"),
			player.get_node_or_null("SkillUltimateButton"),
			player.get_node_or_null("DefendButton")
		]
		for ui in ui_nodes:
			if ui:
				ui.visible = is_paused  # aktifkan saat unpause

	if is_paused:
		# ▶️ Unpause
		if pause_menu_button:
			add_child(pause_menu_button)

		_restore_player_status_bar()

	else:
		# ⏸ Pause
		if pause_menu_button and pause_menu_instance:
			pause_menu_button.get_parent().remove_child(pause_menu_button)

		_move_player_status_bar_to_pause()


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
			var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
			loading.target_scene_path = "res://scenes/ui/MainMenu.tscn"
			get_tree().root.add_child(loading)
			get_tree().current_scene.queue_free()
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
	
	if player_instance.kyle_status.has_method("set_player_status") and player_status_bar:
		player_instance.kyle_status.set_player_status(player_status_bar)

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

# status bar player load
func load_player_status_bar():
	if player_status_bar:
		player_status_bar.queue_free()

	player_status_bar = player_status_bar_scene.instantiate()
	add_child(player_status_bar)
	player_status_bar_original_parent = player_status_bar.get_parent()
