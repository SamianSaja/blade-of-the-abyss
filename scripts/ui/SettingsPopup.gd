extends Control

# Reference to global settings
var game_settings

func _ready():
	# Hide the popup initially
	visible = false
	
	# Get reference to global settings
	game_settings = get_node("/root/GameSettings")
	
	# Connect the close button
	$Panel/VBoxContainer/TitleContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	
	# Connect escape key to close
	set_process_input(true)
	
	# Connect UI controls
	connect_ui_controls()
	
	# Update UI to reflect current settings
	update_ui_values()

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_button_pressed()

func show_popup():
	visible = true
	$Panel/VBoxContainer/TitleContainer/CloseButton.grab_focus()

func _on_close_button_pressed():
	# Save settings before closing
	game_settings.save_settings()
	visible = false
	# Return focus to the main menu
	get_parent().get_node("VBoxContainer/SettingsContainer/SettingsButton").grab_focus()

func connect_ui_controls():
	# Connect volume sliders
	var master_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MasterVolume/MasterVolumeSlider
	var music_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MusicVolume/MusicVolumeSlider
	var sfx_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/SFXVolume/SFXVolumeSlider
	
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect graphics toggles
	var fullscreen_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GraphicsSection/FullscreenToggle
	var vsync_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GraphicsSection/VSyncToggle
	
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	
	# Connect gameplay toggles
	var tutorial_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GameplaySection/ShowTutorialToggle
	var autosave_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GameplaySection/AutoSaveToggle
	
	tutorial_toggle.toggled.connect(_on_tutorial_toggled)
	autosave_toggle.toggled.connect(_on_autosave_toggled)

func update_ui_values():
	# Update volume sliders
	var master_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MasterVolume/MasterVolumeSlider
	var music_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MusicVolume/MusicVolumeSlider
	var sfx_slider = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/SFXVolume/SFXVolumeSlider
	
	master_slider.value = game_settings.master_volume
	music_slider.value = game_settings.music_volume
	sfx_slider.value = game_settings.sfx_volume
	
	# Update volume labels
	var master_label = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MasterVolume/MasterVolumeValue
	var music_label = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MusicVolume/MusicVolumeValue
	var sfx_label = $Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/SFXVolume/SFXVolumeValue
	
	master_label.text = str(int(game_settings.master_volume)) + "%"
	music_label.text = str(int(game_settings.music_volume)) + "%"
	sfx_label.text = str(int(game_settings.sfx_volume)) + "%"
	
	# Update graphics toggles
	var fullscreen_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GraphicsSection/FullscreenToggle
	var vsync_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GraphicsSection/VSyncToggle
	
	fullscreen_toggle.button_pressed = game_settings.fullscreen_enabled
	vsync_toggle.button_pressed = game_settings.vsync_enabled
	
	# Update gameplay toggles
	var tutorial_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GameplaySection/ShowTutorialToggle
	var autosave_toggle = $Panel/VBoxContainer/ContentContainer/VBoxContainer/GameplaySection/AutoSaveToggle
	
	tutorial_toggle.button_pressed = game_settings.show_tutorial
	autosave_toggle.button_pressed = game_settings.auto_save

# Audio control callbacks
func _on_master_volume_changed(value: float):
	game_settings.set_master_volume(value)
	$Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MasterVolume/MasterVolumeValue.text = str(int(value)) + "%"

func _on_music_volume_changed(value: float):
	game_settings.set_music_volume(value)
	$Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/MusicVolume/MusicVolumeValue.text = str(int(value)) + "%"

func _on_sfx_volume_changed(value: float):
	game_settings.set_sfx_volume(value)
	$Panel/VBoxContainer/ContentContainer/VBoxContainer/AudioSection/SFXVolume/SFXVolumeValue.text = str(int(value)) + "%"

# Graphics control callbacks
func _on_fullscreen_toggled(button_pressed: bool):
	game_settings.set_fullscreen(button_pressed)

func _on_vsync_toggled(button_pressed: bool):
	game_settings.set_vsync(button_pressed)

# Gameplay control callbacks
func _on_tutorial_toggled(button_pressed: bool):
	game_settings.set_show_tutorial(button_pressed)

func _on_autosave_toggled(button_pressed: bool):
	game_settings.set_auto_save(button_pressed) 
