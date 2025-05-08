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
	$VBoxContainer/ExitGameContainer/ExitGameButton.pressed.connect(func(): get_tree().quit())


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
	# TODO: tambah loading screen
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://main/Main.tscn")
