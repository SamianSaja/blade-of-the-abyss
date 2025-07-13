extends CanvasLayer

# Ambil semua container menu (satu per tombol menu)
@onready var menu_containers := [
	$VBoxContainer/NewGameContainer,
	$VBoxContainer/LoadGameContainer,
	$VBoxContainer/SettingsContainer,
	$VBoxContainer/HTPContainer,
	$VBoxContainer/CreditsContainer,
	$VBoxContainer/ExitGameContainer
]

var save_system: Node
var settings_popup: Control
var credits_popup: Control
var htp_popup: Control

func _ready():
	var empty_stylebox := StyleBoxEmpty.new()

	for container in menu_containers:
		var icon = container.get_node("SwordIcon")
		if icon:
			icon.visible = false
		
		var button = container.get_child(1)
		if button and button is Button:
			# Hilangkan border dengan StyleBoxEmpty di setiap state
			button.add_theme_stylebox_override("normal", empty_stylebox)
			button.add_theme_stylebox_override("hover", empty_stylebox)
			button.add_theme_stylebox_override("pressed", empty_stylebox)
			button.add_theme_stylebox_override("focus", empty_stylebox)

			button.connect("focus_entered", Callable(self, "_on_button_focus_entered").bind(container))
			button.connect("pressed", Callable(self, "_on_button_pressed").bind(button))
			button.connect("button_up", Callable(self, "_on_button_released").bind(button))

	menu_containers[0].get_child(1).grab_focus()

	$VBoxContainer/NewGameContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/LoadGameContainer/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$VBoxContainer/SettingsContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/HTPContainer/HTPButton.pressed.connect(_on_htp_pressed)
	$VBoxContainer/CreditsContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/ExitGameContainer/ExitGameButton.pressed.connect(func(): get_tree().quit())
	
	# Initialize save system
	save_system = load("res://scripts/data/SaveSystem.gd").new()
	add_child(save_system)
	
	# Update load game button state
	update_load_game_button()
	
	# Initialize popups
	initialize_popups()
	
	# Audio buses are handled by GameSettings autoload

func _on_button_focus_entered(container: Control):
	# Tampilkan ikon pedang hanya pada container aktif
	for cont in menu_containers:
		var icon = cont.get_node("SwordIcon")
		if icon:
			icon.visible = false
	var active_icon = container.get_node("SwordIcon")
	if active_icon:
		active_icon.visible = true

# Warna menyala saat ditekan
func _on_button_pressed(button: Button):
	button.add_theme_color_override("font_color", Color(1, 1, 1))

# Kembalikan warna normal saat dilepas
func _on_button_released(button: Button):
	button.remove_theme_color_override("font_color")

func _on_new_game_pressed():
	var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
	loading.target_scene_path = "res://main/Main.tscn"
	get_tree().root.add_child(loading)
	get_tree().current_scene.queue_free()

func _on_load_game_pressed():
	if save_system.has_save_file():
		print("Load game button pressed - save file exists")
		var loading = load("res://scenes/ui/LoadingScreen.tscn").instantiate()
		loading.target_scene_path = "res://main/Main.tscn"
		loading.load_save_data = true  # Flag untuk load save data
		get_tree().root.add_child(loading)
		get_tree().current_scene.queue_free()
	else:
		print("Load game button pressed - no save file")
		show_no_save_message()

func update_load_game_button():
	var load_button = $VBoxContainer/LoadGameContainer/LoadGameButton
	if save_system.has_save_file():
		load_button.text = "Load Game"
		load_button.disabled = false
	else:
		load_button.text = "No Save Data"
		load_button.disabled = true

func show_no_save_message():
	# Create a simple popup message
	var popup = AcceptDialog.new()
	popup.title = "No Save Data"
	popup.dialog_text = "No save data found. Please start a new game first."
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func initialize_popups():
	# Load and instantiate popup scenes
	settings_popup = load("res://scenes/ui/SettingsPopup.tscn").instantiate()
	credits_popup = load("res://scenes/ui/CreditsPopup.tscn").instantiate()
	htp_popup = load("res://scenes/ui/HowToPlayPopup.tscn").instantiate()
	
	# Add popups to the scene
	add_child(settings_popup)
	add_child(credits_popup)
	add_child(htp_popup)

func _on_settings_pressed():
	settings_popup.show_popup()

func _on_credits_pressed():
	credits_popup.show_popup()

func _on_htp_pressed():
	htp_popup.show_popup()
