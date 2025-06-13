extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "save_data.json"

# Data structure untuk menyimpan game state
var save_data = {
	"player": {
		"hp": 0,
		"mp": 0,
		"tp": 0,
		"max_hp": 0,
		"max_mp": 0,
		"max_tp": 0,
		"power": 0,
		"magic": 0,
		"defense": 0,
		"speed": 0,
		"level": 1,
		"exp": 0,
		"exp_to_next_level": 100
	},
	"support": {
		"hp": 0,
		"mp": 0,
		"tp": 0,
		"max_hp": 0,
		"max_mp": 0,
		"max_tp": 0,
		"power": 0,
		"magic": 0,
		"defense": 0,
		"speed": 0,
		"level": 1,
		"exp": 0,
		"exp_to_next_level": 100
	},
	"inventory": {
		"items": [],
		"armor": []
	},
	"game_progress": {
		"current_world": "",
		"player_position": {
			"x": 0,
			"y": 0,
			"z": 0
		},
		"completed_quests": []
	}
}

func _ready():
	# Buat direktori save jika belum ada
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

# Fungsi untuk menyimpan data
func save_game(player_status, support_status, inventory, game_progress):
	# Update save data dengan data terbaru
	save_data.player = {
		"hp": player_status.hp,
		"mp": player_status.mp,
		"tp": player_status.tp,
		"max_hp": player_status.max_hp,
		"max_mp": player_status.max_mp,
		"max_tp": player_status.max_tp,
		"power": player_status.power,
		"magic": player_status.magic,
		"defense": player_status.defense,
		"speed": player_status.speed,
		"level": player_status.level,
		"exp": player_status.exp,
		"exp_to_next_level": player_status.exp_to_next_level
	}
	
	save_data.support = {
		"hp": support_status.hp,
		"mp": support_status.mp,
		"tp": support_status.tp,
		"max_hp": support_status.max_hp,
		"max_mp": support_status.max_mp,
		"max_tp": support_status.max_tp,
		"power": support_status.power,
		"magic": support_status.magic,
		"defense": support_status.defense,
		"speed": support_status.speed,
		"level": support_status.level,
		"exp": support_status.exp,
		"exp_to_next_level": support_status.exp_to_next_level
	}
	
	save_data.inventory = inventory
	save_data.game_progress = game_progress
	
	# Simpan ke file
	var save_file = FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved successfully!")
		return true
	else:
		print("Error saving game!")
		return false

# Fungsi untuk memuat data
func load_game():
	if not FileAccess.file_exists(SAVE_DIR + SAVE_FILE):
		print("No save file found!")
		return null
		
	var save_file = FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			save_data = json.get_data()
			print("Game loaded successfully!")
			return save_data
		else:
			print("Error parsing save file!")
			return null
	else:
		print("Error opening save file!")
		return null

# Fungsi untuk mengecek apakah ada save file
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE)

# Fungsi untuk menghapus save file
func delete_save_file() -> bool:
	if has_save_file():
		var dir = DirAccess.open(SAVE_DIR)
		if dir:
			dir.remove(SAVE_FILE)
			print("Save file deleted!")
			return true
	return false 