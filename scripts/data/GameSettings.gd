extends Node

# Singleton for managing game settings globally

# Audio settings
var master_volume: float = 100.0
var music_volume: float = 80.0
var sfx_volume: float = 90.0

# Graphics settings
var fullscreen_enabled: bool = false
var vsync_enabled: bool = true

# Gameplay settings
var show_tutorial: bool = true
var auto_save: bool = true

# Signal for when settings change
signal settings_changed(setting_name: String, value)

func _ready():
	# Initialize audio buses if they don't exist
	initialize_audio_buses()
	
	load_settings()
	apply_settings()

func initialize_audio_buses():
	# Check if Music bus exists, if not create it
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_idx, "Music")
		AudioServer.set_bus_send(music_bus_idx, "Master")
	
	# Check if SFX bus exists, if not create it
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var sfx_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_bus_idx, "SFX")
		AudioServer.set_bus_send(sfx_bus_idx, "Master")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Load audio settings
		master_volume = config.get_value("audio", "master_volume", 100.0)
		music_volume = config.get_value("audio", "music_volume", 80.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 90.0)
		
		# Load graphics settings
		fullscreen_enabled = config.get_value("graphics", "fullscreen", false)
		vsync_enabled = config.get_value("graphics", "vsync", true)
		
		# Load gameplay settings
		show_tutorial = config.get_value("gameplay", "show_tutorial", true)
		auto_save = config.get_value("gameplay", "auto_save", true)

func save_settings():
	var config = ConfigFile.new()
	
	# Save audio settings
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Save graphics settings
	config.set_value("graphics", "fullscreen", fullscreen_enabled)
	config.set_value("graphics", "vsync", vsync_enabled)
	
	# Save gameplay settings
	config.set_value("gameplay", "show_tutorial", show_tutorial)
	config.set_value("gameplay", "auto_save", auto_save)
	
	config.save("user://settings.cfg")

func apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume / 100.0))
	
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx != -1:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume / 100.0))
	
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume / 100.0))
	
	# Apply graphics settings
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)

# Audio setting functions
func set_master_volume(value: float):
	master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))
	settings_changed.emit("master_volume", value)

func set_music_volume(value: float):
	music_volume = value
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx != -1:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value / 100.0))
	settings_changed.emit("music_volume", value)

func set_sfx_volume(value: float):
	sfx_volume = value
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value / 100.0))
	settings_changed.emit("sfx_volume", value)

# Graphics setting functions
func set_fullscreen(enabled: bool):
	fullscreen_enabled = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit("fullscreen", enabled)

func set_vsync(enabled: bool):
	vsync_enabled = enabled
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)
	settings_changed.emit("vsync", enabled)

# Gameplay setting functions
func set_show_tutorial(enabled: bool):
	show_tutorial = enabled
	settings_changed.emit("show_tutorial", enabled)

func set_auto_save(enabled: bool):
	auto_save = enabled
	settings_changed.emit("auto_save", enabled) 
