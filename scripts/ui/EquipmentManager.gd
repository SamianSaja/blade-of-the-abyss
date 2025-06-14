extends Node

# Data armor yang tersedia
var all_armors = [
	{"name": "Letter Armor", "icon": preload("res://assets/inventory/armor/letter-armor.png"), "bonus": {"defense": 5, "hp": 20}},
	{"name": "Plate Armor", "icon": preload("res://assets/inventory/armor/plate-armor.png"), "bonus": {"defense": 10, "hp": 40}},
	{"name": "Royal Armor", "icon": preload("res://assets/inventory/armor/royal-armor.png"), "bonus": {"defense": 20, "hp": 80}},
	{"name": "Mage Robe", "icon": preload("res://assets/inventory/armor/mage-robe.png"), "bonus": {"defense": 8, "hp": 30}},
	{"name": "Sorcerer Cloak", "icon": preload("res://assets/inventory/armor/sorcerer-cloak.png"), "bonus": {"defense": 12, "hp": 50}},
	{"name": "Royal Enchanter's Vestments", "icon": preload("res://assets/inventory/armor/royal-enchanter-vesments.png"), "bonus": {"defense": 18, "hp": 70}},
]

# Armor yang sedang dipakai
var equipped = {
	"Kyle": null,
	"Nora": null
}

# Status peningkatan armor (misal: level up)
var armor_upgrade = {
	"Letter Armor": 0,
	"Plate Armor": 0,
	"Royal Armor": 0,
	"Mage Robe": 0,
	"Sorcerer Cloak": 0,
	"Royal Enchanter's Vestments": 0,
}

func equip_armor(character: String, armor_name: String):
	equipped[character] = armor_name

func unequip_armor(character: String):
	equipped[character] = null

func upgrade_armor(armor_name: String):
	armor_upgrade[armor_name] += 1

func get_equipped_armor(character: String):
	return equipped[character]

func get_armor_status(armor_name: String):
	var base = null
	for a in all_armors:
		if a["name"] == armor_name:
			base = a
			break
	var level = armor_upgrade.get(armor_name, 0)
	if base:
		var bonus = base["bonus"].duplicate()
		# Contoh: setiap upgrade +10% bonus
		for k in bonus.keys():
			bonus[k] += int(bonus[k] * 0.1 * level)
		return {"level": level, "bonus": bonus}
	return null

func get_all_armors():
	return all_armors 
 
