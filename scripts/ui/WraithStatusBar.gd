extends Control

@onready var hp_bar: TextureProgressBar = $TextureProgressBar

# Menerima HP, MP, TP, tapi hanya menampilkan bar HP
func set_status(hp: int, max_hp: int, mp: int, max_mp: int, tp: int, max_tp: int):
	hp_bar.max_value = max_hp
	hp_bar.value = hp

	#mp_bar.max_value = max_mp
	#mp_bar.value = mp
#
	#tp_bar.max_value = max_tp
	#tp_bar.value = tp
