extends Node

@onready var player_scene = preload("res://scenes/characters/Player.tscn")
@onready var support_scene = preload("res://scenes/characters/NoraPlayerSupport.tscn")
@onready var camera_scene = preload("res://scenes/Camera3D.tscn")
@onready var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")
@onready var player_status_bar_scene = preload("res://scenes/ui/PlayerStatusBar.tscn")
@onready var support_status_bar_scene = preload("res://scenes/ui/SupportStatusBar.tscn")
@onready var dialog_box_scene = preload("res://scenes/ui/DialogBox.tscn")

@export var item_template: PackedScene

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

# inventory
var item_data = [
	{"name": "Health Potion", "icon": preload("res://assets/inventory/items/potion.png")},
	{"name": "Mana Potion", "icon": preload("res://assets/inventory/items/mana-potion.png")},
	{"name": "Technical Potion", "icon": preload("res://assets/inventory/items/technical-potion.png")},
	{"name": "Skill Scrolls", "icon": preload("res://assets/inventory/items/skill-scrolls.png")},
]

var armor_data = [
	{"name": "Letter Armor", "icon": preload("res://assets/inventory/armor/letter-armor.png")},
	{"name": "Plate Armor", "icon": preload("res://assets/inventory/armor/plate-armor.png")},
	{"name": "Royal Armor", "icon": preload("res://assets/inventory/armor/royal-armor.png")},
	{"name": "Mage Robe", "icon": preload("res://assets/inventory/armor/mage-robe.png")},
	{"name": "Sorcerer Cloak", "icon": preload("res://assets/inventory/armor/sorcerer-cloak.png")},
	{"name": "Royal Enchanter's Vestments", "icon": preload("res://assets/inventory/armor/royal-enchanter-vesments.png")},
]


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
var dialog_box: CanvasLayer

# Managers
var pause_menu_manager: Node
var world_manager: Node
var dialog_manager: Node
var inventory_manager: Node
var equipment_manager: Node

func _ready():
	# Initialize managers
	pause_menu_manager = load("res://scripts/ui/PauseMenuManager.gd").new()
	add_child(pause_menu_manager)
	
	world_manager = load("res://scripts/world/WorldManager.gd").new()
	add_child(world_manager)
	
	dialog_manager = load("res://scripts/ui/DialogManager.gd").new()
	add_child(dialog_manager)
	
	inventory_manager = load("res://scripts/ui/InventoryManager.gd").new()
	inventory_manager.item_template = item_template
	add_child(inventory_manager)

	equipment_manager = load("res://scripts/ui/EquipmentManager.gd").new()
	add_child(equipment_manager)

	# Load default world
	world_manager.load_world("altar_room")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		pause_menu_manager.toggle_pause()

func spawn_player(world_name: String):
	if player_instance:
		player_instance.queue_free()

	player_instance = player_scene.instantiate()

	var spawn_point = world_manager.world_instance.get_node_or_null("PlayerSpawn")
	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO
	add_child(player_instance)

	spawn_camera(world_name)
	world_manager.spawn_world_enemy(world_name)

	if player_instance.kyle_status.has_method("set_player_status") and pause_menu_manager.player_status_bar:
		player_instance.kyle_status.set_player_status(pause_menu_manager.player_status_bar)
	spawn_support(world_name)

func spawn_player_with_custom_spawn(world_name: String, spawn_point_name: String):
	if player_instance:
		player_instance.queue_free()

	player_instance = player_scene.instantiate()

	var spawn_point = world_manager.world_instance.get_node_or_null(spawn_point_name)
	if spawn_point:
		player_instance.global_transform.origin = spawn_point.global_transform.origin
	else:
		player_instance.global_transform.origin = Vector3.ZERO

	add_child(player_instance)
	spawn_camera(world_name)
	world_manager.spawn_world_enemy(world_name)

	if player_instance.kyle_status.has_method("set_player_status") and pause_menu_manager.player_status_bar:
		player_instance.kyle_status.set_player_status(pause_menu_manager.player_status_bar)
	
	spawn_support(world_name)

func spawn_support(world_name: String):
	if support_instance:
		support_instance.queue_free()
	
	support_instance = support_scene.instantiate()
	var spawn_point = world_manager.world_instance.get_node_or_null("SupportSpawn")
	if player_instance:
		support_instance.global_transform.origin = player_instance.global_transform.origin + Vector3(0, 0, -5)
	else:
		if spawn_point:
			support_instance.global_transform.origin = spawn_point.global_transform.origin
		else:
			support_instance.global_transform.origin = Vector3.ZERO
	add_child(support_instance)

	if support_instance.nora_status.has_method("set_support_status") and pause_menu_manager.support_status_bar:
		support_instance.nora_status.set_support_status(pause_menu_manager.support_status_bar)

func spawn_camera(world_name: String):
	if camera_instance:
		camera_instance.queue_free()

	camera_instance = camera_scene.instantiate()
	camera_instance.set_script(load("res://scripts/CameraFollow.gd"))
	camera_instance.player_path = player_instance.get_path()
	if world_manager.camera_limits_by_world.has(world_name):
		var limits = world_manager.camera_limits_by_world[world_name]
		camera_instance.min_x = limits["min_x"]
		camera_instance.max_x = limits["max_x"]
		camera_instance.min_z = limits["min_z"]
		camera_instance.max_z = limits["max_z"]
		camera_instance.fixed_y = limits["fixed_y"]
	add_child(camera_instance)

func play_story_if_any(world_name: String):
	dialog_manager.play_story_if_any(world_name)
