extends Control

@onready var progress_bar: TextureProgressBar = $TextureProgressBar

func set_status(current_hp: int, max_hp: int):
	progress_bar.value = current_hp
	progress_bar.max_value = max_hp
