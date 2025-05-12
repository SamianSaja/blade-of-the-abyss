extends Control

@onready var progress_bar: TextureProgressBar = $TextureProgressBar

# Menerima HP, MP, TP, tapi hanya menampilkan bar HP
func set_status(hp: int, max_hp: int, mp: int, max_mp: int, tp: int = 0, max_tp: int = 0):
	progress_bar.value = hp
	progress_bar.max_value = max_hp
