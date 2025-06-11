# ItemTemplate.gd
extends Control

var item_data: Item

func setup(item: Item):
	item_data = item
	$Icon.texture = item.icon
	$NameLabel.text = item.name
	
	if item is Armor:
		var armor_item := item as Armor
		$ExtraLabel.text = "DEF: %d" % armor_item.defense
	else:
		$ExtraLabel.text = "" # kosong untuk item biasa
