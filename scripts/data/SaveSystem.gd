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
	"equipment": {
		"kyle_armor": null,
		"nora_armor": null,
		"armor_upgrades": {}
	},
	"game_progress": {
		"current_world": "",
		"player_position": {
			"x": 0,
			"y": 0,
			"z": 0
		},
		"support_position": {
			"x": 0,
			"y": 0,
			"z": 0
		},
		"last_save_point": "",
		"completed_quests": [],
		"game_time": 0
	},
	"save_info": {
		"save_date": "",
		"play_time": 0,
		"save_version": "1.0"
	}
}

func _ready():
	# Buat direktori save jika belum ada
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

# Fungsi untuk menyimpan data dari crystal point
func save_at_crystal_point(game_instance):
	if not game_instance:
		print("Error: Game instance not found!")
		return false
	
	var player = game_instance.player_instance
	var support = game_instance.support_instance
	var world_manager = game_instance.world_manager
	var equipment_manager = game_instance.equipment_manager
	
	if not player or not support:
		print("Error: Player or support not found!")
		return false
	
	# Update save data dengan data terbaru
	save_data.player = {
		"hp": player.kyle_status.hp,
		"mp": player.kyle_status.mp,
		"tp": player.kyle_status.tp,
		"max_hp": player.kyle_status.max_hp,
		"max_mp": player.kyle_status.max_mp,
		"max_tp": player.kyle_status.max_tp,
		"power": player.kyle_status.power,
		"magic": player.kyle_status.magic,
		"defense": player.kyle_status.defense,
		"speed": player.kyle_status.speed,
		"level": player.kyle_status.level,
		"exp": player.kyle_status.exp,
		"exp_to_next_level": player.kyle_status.exp_to_next_level
	}
	
	save_data.support = {
		"hp": support.nora_status.hp,
		"mp": support.nora_status.mp,
		"tp": support.nora_status.tp,
		"max_hp": support.nora_status.max_hp,
		"max_mp": support.nora_status.max_mp,
		"max_tp": support.nora_status.max_tp,
		"power": support.nora_status.power,
		"magic": support.nora_status.magic,
		"defense": support.nora_status.defense,
		"speed": support.nora_status.speed,
		"level": support.nora_status.level,
		"exp": support.nora_status.exp,
		"exp_to_next_level": support.nora_status.exp_to_next_level
	}
	
	# Save equipment data
	save_data.equipment = {
		"kyle_armor": equipment_manager.get_equipped_armor("Kyle"),
		"nora_armor": equipment_manager.get_equipped_armor("Nora"),
		"armor_upgrades": equipment_manager.armor_upgrade.duplicate()
	}
	
	# Save game progress
	save_data.game_progress = {
		"current_world": world_manager.get_current_world_name(),
		"player_position": {
			"x": player.global_transform.origin.x,
			"y": player.global_transform.origin.y,
			"z": player.global_transform.origin.z
		},
		"support_position": {
			"x": support.global_transform.origin.x,
			"y": support.global_transform.origin.y,
			"z": support.global_transform.origin.z
		},
		"last_save_point": "CrystalPoint",
		"completed_quests": [], # TODO: Implement quest system
		"game_time": Time.get_ticks_msec() / 1000.0
	}
	
	print("Saving game progress:")
	print("  Current world: ", save_data.game_progress.current_world)
	print("  Player position: ", save_data.game_progress.player_position)
	print("  Support position: ", save_data.game_progress.support_position)
	
	# Save metadata
	save_data.save_info = {
		"save_date": Time.get_datetime_string_from_system(),
		"play_time": Time.get_ticks_msec() / 1000.0,
		"save_version": "1.0"
	}
	
	# Simpan ke file
	var save_file = FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved successfully at Crystal Point!")
		
		# Debug: verify save data
		debug_print_save_file()
		
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
			
			# Debug info
			if save_data.has("game_progress"):
				var progress = save_data.game_progress
				print("Loaded game progress:")
				print("  Current world: ", progress.get("current_world", "unknown"))
				print("  Player position: ", progress.get("player_position", {}))
				print("  Support position: ", progress.get("support_position", {}))
			
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

# Fungsi untuk mendapatkan info save file
func get_save_info():
	if has_save_file():
		var data = load_game()
		if data and data.has("save_info"):
			return data.save_info
	return null

# Debug function to print save file contents
func debug_print_save_file():
	if has_save_file():
		var data = load_game()
		if data:
			print("=== SAVE FILE CONTENTS ===")
			print("Save Info: ", data.get("save_info", {}))
			print("Current World: ", data.get("game_progress", {}).get("current_world", "unknown"))
			print("Player Position: ", data.get("game_progress", {}).get("player_position", {}))
			print("Support Position: ", data.get("game_progress", {}).get("support_position", {}))
			print("Player HP: ", data.get("player", {}).get("hp", 0))
			print("Support HP: ", data.get("support", {}).get("hp", 0))
			print("==========================")
		else:
			print("Failed to load save data for debugging")
	else:
		print("No save file found for debugging")

# Fungsi untuk apply loaded data ke game
func apply_save_data(game_instance, save_data):
	if not game_instance or not save_data:
		return false
	
	var player = game_instance.player_instance
	var support = game_instance.support_instance
	var equipment_manager = game_instance.equipment_manager
	
	if not player or not support:
		return false
	
	# Apply player status
	if save_data.has("player"):
		var player_data = save_data.player
		player.kyle_status.hp = player_data.hp
		player.kyle_status.mp = player_data.mp
		player.kyle_status.tp = player_data.tp
		player.kyle_status.max_hp = player_data.max_hp
		player.kyle_status.max_mp = player_data.max_mp
		player.kyle_status.max_tp = player_data.max_tp
		player.kyle_status.power = player_data.power
		player.kyle_status.magic = player_data.magic
		player.kyle_status.defense = player_data.defense
		player.kyle_status.speed = player_data.speed
		player.kyle_status.level = player_data.level
		player.kyle_status.exp = player_data.exp
		player.kyle_status.exp_to_next_level = player_data.exp_to_next_level
		player.kyle_status.update_status_player()
	
	# Apply support status
	if save_data.has("support"):
		var support_data = save_data.support
		support.nora_status.hp = support_data.hp
		support.nora_status.mp = support_data.mp
		support.nora_status.tp = support_data.tp
		support.nora_status.max_hp = support_data.max_hp
		support.nora_status.max_mp = support_data.max_mp
		support.nora_status.max_tp = support_data.max_tp
		support.nora_status.power = support_data.power
		support.nora_status.magic = support_data.magic
		support.nora_status.defense = support_data.defense
		support.nora_status.speed = support_data.speed
		support.nora_status.level = support_data.level
		support.nora_status.exp = support_data.exp
		support.nora_status.exp_to_next_level = support_data.exp_to_next_level
		support.nora_status.update_support_status()
	
	# Apply equipment
	if save_data.has("equipment"):
		var equip_data = save_data.equipment
		if equip_data.has("kyle_armor") and equip_data.kyle_armor:
			equipment_manager.equip_armor("Kyle", equip_data.kyle_armor)
		if equip_data.has("nora_armor") and equip_data.nora_armor:
			equipment_manager.equip_armor("Nora", equip_data.nora_armor)
		if equip_data.has("armor_upgrades"):
			equipment_manager.armor_upgrade = equip_data.armor_upgrades.duplicate()
	
	# Note: Positions are already applied during spawning, so we don't override them here
	# This prevents conflicts with the spawn functions that set positions from save data
	
	return true 