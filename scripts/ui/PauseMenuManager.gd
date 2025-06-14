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

# Tambahkan variabel untuk rotasi
enum DragState { NONE, ROTATING }
var drag_state := DragState.NONE
var last_mouse_pos := Vector2.ZERO

signal pause_toggled(is_paused: bool)

func _ready():
	pause_menu_button = pause_menu_button_scene.instantiate()
	add_child(pause_menu_button)
	pause_menu_button.connect("pause_menu_button_pressed", Callable(self, "toggle_pause"))
	setup_pause_menu()

	# Tambahkan koneksi input pada CharacterViewport
	var equipments_panel = pause_menu_instance.get_node("EquipmentsPanel")
	var viewport_container = equipments_panel.get_node("CharacterViewport")
	viewport_container.gui_input.connect(_on_viewport_gui_input)

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
	var equipments_panel = pause_menu_instance.get_node_or_null("EquipmentsPanel")

	# Hide all by default
	bg_status_bar.visible = false
	kyle_status_bar.visible = false
	nora_status_bar.visible = false
	bg_inventory.visible = false
	inventory_tabs.visible = false
	if equipments_panel:
		equipments_panel.visible = false
	
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
			print("Equipments tab shown")
			if equipments_panel:
				print("Equipments panel shown")
				equipments_panel.visible = true
				show_equipments_panel()
		"Skills":
			# You can create skill population logic here
			print("Skills tab shown, implement logic if needed")

# --- EQUIPMENTS PANEL LOGIC ---
var current_equipment_character := "Kyle"
var current_equipment_model: Node = null

func show_equipments_panel():
	print("pause menu", pause_menu_instance)
	var equipments_panel = pause_menu_instance.get_node("EquipmentsPanel")
	var kyle_btn = equipments_panel.get_node("CharacterTab/Kyle")
	var nora_btn = equipments_panel.get_node("CharacterTab/Nora")

	# Default: Kyle
	update_character_model(current_equipment_character)
	update_armor_list(current_equipment_character)

	kyle_btn.pressed.connect(func():
		current_equipment_character = "Kyle"
		update_character_model("Kyle")
		update_armor_list("Kyle")
	)
	nora_btn.pressed.connect(func():
		current_equipment_character = "Nora"
		update_character_model("Nora")
		update_armor_list("Nora")
	)

func update_character_model(character):
	var equipments_panel = pause_menu_instance.get_node("EquipmentsPanel")
	var viewport_container = equipments_panel.get_node("CharacterViewport")
	var viewport = null
	for child in viewport_container.get_children():
		if child is Viewport:
			viewport = child
			break
	if viewport == null:
		viewport = Viewport.new.call()
		viewport.size = Vector2(100, 200)
		viewport.disable_3d = false
		viewport.transparent_bg = true
		viewport_container.add_child(viewport)

	# Clear previous model
	for c in viewport.get_children():
		viewport.remove_child(c)
		c.queue_free()

	# Add camera to viewport
	var camera = Camera3D.new()
	camera.transform.origin = Vector3(1000, 1, 3)  # Position camera to view character
	camera.look_at(Vector3(0, 1, 0))  # Look at character's center
	viewport.add_child(camera)

	# Use preview scene for UI
	var model_scene = load("res://scenes/characters/KylePreview.tscn" if character == "Kyle" else "res://scenes/characters/NoraPreview.tscn")
	current_equipment_model = model_scene.instantiate()
	#current_equipment_model.transform.origin = Vector3(1000, 0, 0)  # Center in viewport
	viewport.add_child(current_equipment_model)

	# Play idle animation jika ada
	if current_equipment_model.has_node("AnimationPlayer"):
		var anim = current_equipment_model.get_node("AnimationPlayer")
		if anim.has_animation("idle"):
			anim.get_animation("idle").loop = true
			anim.play("idle")
		else:
			anim.get_animation("nora-idle").loop = true
			anim.play("nora-idle")

func update_armor_list(character):
	print("pause menu update ", pause_menu_instance)
	var equipments_panel = pause_menu_instance.get_node("EquipmentsPanel")
	var armor_panel = equipments_panel.get_node("ArmorPanel")
	var armor_list = armor_panel.get_node("Armor")
	# Clear list
	for c in armor_list.get_children():
		c.queue_free()

	var equipment_manager = get_parent().equipment_manager
	var equipped_armor = equipment_manager.get_equipped_armor(character)
	var kyle_armors = ["Letter Armor", "Plate Armor", "Royal Armor"]

	for armor in equipment_manager.get_all_armors():
		var is_kyle_armor = kyle_armors.has(armor["name"])
		if character == "Kyle" and not is_kyle_armor:
			continue
		if character == "Nora" and is_kyle_armor:
			continue
		var btn = Button.new()
		btn.text = armor["name"]
		if armor["name"] == equipped_armor:
			btn.text += " (Equipped)"
		btn.connect("pressed", func():
			if equipped_armor == armor["name"]:
				equipment_manager.unequip_armor(character)
			else:
				equipment_manager.equip_armor(character, armor["name"])
			update_armor_list(character)
			update_armor_status(armor["name"], character)
		)
		armor_list.add_child(btn)
		# Show status on first or equipped
		if armor["name"] == equipped_armor or equipped_armor == null:
			update_armor_status(armor["name"], character)

func update_armor_status(armor_name, character):
	var equipments_panel = pause_menu_instance.get_node("EquipmentsPanel")
	var armor_panel = equipments_panel.get_node("ArmorPanel")
	var armor_status = armor_panel.get_node_or_null("ArmorStatus")
	if armor_status:
		armor_status.get_children().map(func(c): c.queue_free())
		var equipment_manager = get_parent().equipment_manager
		var status = equipment_manager.get_armor_status(armor_name)
		if status:
			var label = Label.new()
			label.text = "%s\nLevel: %d\nBonus: %s" % [armor_name, status["level"], str(status["bonus"])]
			armor_status.add_child(label)

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
	
	var equipments_button = pause_menu_instance.get_node_or_null("VBoxContainer/EquipmentsContainer/EquipmentsButton")
	if equipments_button:
		equipments_button.pressed.connect(func ():
			show_pause_menu_section("Equipments")
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


func _on_viewport_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_state = DragState.ROTATING
				last_mouse_pos = event.position
			else:
				drag_state = DragState.NONE
	elif event is InputEventMouseMotion and drag_state == DragState.ROTATING and current_equipment_model:
		var delta = event.position.x - last_mouse_pos.x
		current_equipment_model.rotate_y(-delta * 0.01) # Sesuaikan sensitivitas jika perlu
		last_mouse_pos = event.position
