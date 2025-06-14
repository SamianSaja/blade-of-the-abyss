extends Node

@export var item_template: PackedScene

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

func populate_item_list():
	var item_tab = get_parent().pause_menu_manager.pause_menu_instance.get_node("InventoryTabs/ItemTab/ItemList")
	_clear_container(item_tab)
	
	item_tab.add_theme_constant_override("separation", 40)

	for data in item_data:
		var item = item_template.instantiate()
		item.get_node("Icon").texture = data["icon"]
		item.get_node("NameLabel").text = data["name"]
		item_tab.add_child(item)

func populate_armor_list():
	var armor_tab = get_parent().pause_menu_manager.pause_menu_instance.get_node("InventoryTabs/ArmorTab/ArmorList")
	_clear_container(armor_tab)
	
	armor_tab.add_theme_constant_override("separation", 40) 

	for data in armor_data:
		var armor = item_template.instantiate()
		armor.get_node("Icon").texture = data["icon"]
		armor.get_node("NameLabel").text = data["name"]
		armor_tab.add_child(armor)

func _clear_container(container):
	for child in container.get_children():
		child.queue_free() 
