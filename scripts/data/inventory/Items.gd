# Item.gd
extends Resource
class_name Item

@export var name: String
@export var description: String
@export var price: int
@export var icon: Texture2D
@export var item_type: String = "Item" # default "Item"
