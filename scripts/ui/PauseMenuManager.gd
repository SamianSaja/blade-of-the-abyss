extends Node

@onready var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_menu_button_scene = preload("res://scenes/ui/PauseMenuButton.tscn")
@onready var player_status_bar_scene = preload("res://scenes/ui/PlayerStatusBar.tscn")
@onready var support_status_bar_scene = preload("res://scenes/ui/SupportStatusBar.tscn")

var pause_menu_instance: CanvasLayer
var pause_menu_button: TouchScreenButton
var pause_menu_button_original_parent: Node
var player_status_bar: CanvasLayer
var player_status_bar_original_parent: Node
var support_status_bar: CanvasLayer
var support_status_bar_original_parent: Node

signal pause_toggled(is_paused: bool)

func _ready():
	pause_menu_button = pause_menu_button_scene.instantiate()
	add_child(pause_menu_button)
	pause_menu_button.connect("pause_menu_button_pressed", Callable(self, "toggle_pause"))
	setup_pause_menu()

func toggle_pause():
	var is_paused = get_tree().paused
	get_tree().paused = !is_paused
	pause_menu_instance.visible = !is_paused

	if get_parent().player_instance:
		var ui_nodes := [
			get_parent().player_instance.get_node_or_null("Joystick"),
			get_parent().player_instance.get_node_or_null("AttackController"),
			get_parent().player_instance.get_node_or_null("SkillOneButton"),
			get_parent().player_instance.get_node_or_null("SkillTwoButton"),
			get_parent().player_instance.get_node_or_null("SkillThreeButton"),
			get_parent().player_instance.get_node_or_null("SkillFourButton"),
			get_parent().player_instance.get_node_or_null("SkillUltimateButton"),
			get_parent().player_instance.get_node_or_null("DefendButton")
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
	
		# Set default pause menu to Status tab
		show_pause_menu_section("Status")
	
	emit_signal("pause_toggled", !is_paused)

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

			var container_child = container.get_node_or_null("HBoxContainer")

			var vbox = container_child.get_node_or_null("VBoxContainer")
			var vbox_label = container_child.get_node_or_null("VBoxContainerLabel")
			if vbox:
				vbox.add_theme_constant_override("separation", 27)
			if vbox_label:
				vbox_label.visible = false

func _move_player_status_bar_to_pause():
	if player_status_bar and pause_menu_instance:
		player_status_bar.get_parent().remove_child(player_status_bar)
		pause_menu_instance.add_child(player_status_bar)

		var container = player_status_bar.get_node_or_null("MarginContainer")
		container.visible = false
		
		if container:
			container.anchor_left = 0.7
			container.anchor_top = 0.2
			container.anchor_right = 0.7
			container.anchor_bottom = 0.2
			container.offset_left = 20
			container.offset_top = -40
			
			var container_child = container.get_node_or_null("HBoxContainer")
			if container_child:
				container_child.add_theme_constant_override("separation", -220)
				container_child.offset_top = -40

			var vbox = container_child.get_node_or_null("VBoxContainer")
			var vbox_label = container_child.get_node_or_null("VBoxContainerLabel")
			if vbox:
				vbox.add_theme_constant_override("separation", 140)
			if vbox_label:
				vbox_label.visible = true
				vbox_label.add_theme_constant_override("separation", 103)
		var status_button = pause_menu_instance.get_node_or_null("VBoxContainer/StatusContainer/StatusButton")
		status_button.pressed.connect(func ():
			container.visible = true
		)

func _restore_support_status_bar():
	if support_status_bar and support_status_bar_original_parent:
		support_status_bar.get_parent().remove_child(support_status_bar)
		support_status_bar_original_parent.add_child(support_status_bar)

		var container = support_status_bar.get_node_or_null("MarginContainer")
		if container:
			container.anchor_left = 0.02
			container.anchor_top = 0.04
			container.anchor_right = 0.02
			container.anchor_bottom = 0.04
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
		container.visible = false
		if container:
			container.anchor_left = 0.7
			container.anchor_top = 0.4
			container.anchor_right = 0.7
			container.anchor_bottom = 0.4
			container.offset_left = 20
			container.offset_top = 70

			var vbox = container.get_node_or_null("VBoxContainer")
			if vbox:
				vbox.add_theme_constant_override("separation", 140)
		
		var status_button = pause_menu_instance.get_node_or_null("VBoxContainer/StatusContainer/StatusButton")
		status_button.pressed.connect(func ():
			container.visible = true
		)

func show_pause_menu_section(section: String):
	var bg_status_bar = pause_menu_instance.get_node_or_null("Panel/StatusBarContainer")
	var kyle_status_bar = pause_menu_instance.get_node_or_null("CharacterStatusKyle")
	var nora_status_bar = pause_menu_instance.get_node_or_null("CharacterStatusNora")
	var bg_inventory = pause_menu_instance.get_node_or_null("Panel/BgInventoryList")
	var inventory_tabs = pause_menu_instance.get_node_or_null("InventoryTabs")

	# Hide all by default
	bg_status_bar.visible = false
	kyle_status_bar.visible = false
	nora_status_bar.visible = false
	bg_inventory.visible = false
	inventory_tabs.visible = false
	
	var player_container = null
	var support_container = null
	
	# Hide status bar by default
	if player_status_bar:
		player_container = player_status_bar.get_node_or_null("MarginContainer")
		if player_container:
			player_container.visible = false
	if support_status_bar:
		support_container = support_status_bar.get_node_or_null("MarginContainer")
		if support_container:
			support_container.visible = false

	# Show based on requested section
	match section:
		"Status":
			bg_status_bar.visible = true
			kyle_status_bar.visible = true
			nora_status_bar.visible = true
			# show status bars when Status tab active
			if player_container:
				player_container.visible = true
			if support_container:
				support_container.visible = true
		"Inventory":
			bg_inventory.visible = true
			inventory_tabs.visible = true
			get_parent().inventory_manager.populate_item_list()
			get_parent().inventory_manager.populate_armor_list()
		"Equipments":
			bg_inventory.visible = true
			inventory_tabs.visible = true
			# assuming Equipments is tab 1
			inventory_tabs.current_tab = 1
		"Skills":
			# You can create skill population logic here
			print("Skills tab shown, implement logic if needed")

func setup_pause_menu():
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.visible = false
	
	# define for switch
	var bg_status_bar = pause_menu_instance.get_node_or_null("Panel/StatusBarContainer")
	var kyle_status_bar = pause_menu_instance.get_node_or_null("CharacterStatusKyle")
	var nora_status_bar = pause_menu_instance.get_node_or_null("CharacterStatusNora")
	var bg_inventory = pause_menu_instance.get_node_or_null("Panel/BgInventoryList")
	var inventory_tabs = pause_menu_instance.get_node("InventoryTabs")
	
	# default pause menu
	bg_status_bar.visible = true
	kyle_status_bar.visible = true
	nora_status_bar.visible = true
	bg_inventory.visible = false
	inventory_tabs.visible = false

	# resume button
	var resume_button = pause_menu_instance.get_node_or_null("VBoxContainer/ResumeContainer/ResumeButton")
	if resume_button:
		resume_button.pressed.connect(toggle_pause)
	
	var status_button = pause_menu_instance.get_node_or_null("VBoxContainer/StatusContainer/StatusButton")
	if status_button:
		status_button.pressed.connect(func ():
			show_pause_menu_section("Status")
		)

	var inventory_button = pause_menu_instance.get_node_or_null("VBoxContainer/InventoryContainer/InventoryButton")
	if inventory_button:
		inventory_button.pressed.connect(func ():
			show_pause_menu_section("Inventory")
		)

	var return_button = pause_menu_instance.get_node_or_null("ReturnMainMenu")
	if return_button:
		return_button.pressed.connect(func ():
			get_tree().paused = false
			var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
			loading.target_scene_path = "res://scenes/ui/MainMenu.tscn"
			get_tree().root.add_child(loading)
			get_tree().current_scene.queue_free()
		)

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
