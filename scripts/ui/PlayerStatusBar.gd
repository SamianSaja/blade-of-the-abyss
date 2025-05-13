extends CanvasLayer

@onready var hp_bar = $MarginContainer/VBoxContainer/HpBar
@onready var mp_bar = $MarginContainer/VBoxContainer/MpBar
@onready var tp_bar = $MarginContainer/VBoxContainer/TpBar

var speed = 0
var max_speed = 0

func set_status(
		hp: int,
		max_hp: int,
		mp: int,
		max_mp: int,
		tp: int,
		max_tp: int,
		speed: int,
		max_speed: int
	):
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	
	mp_bar.max_value = max_mp
	mp_bar.value = mp

	tp_bar.max_value = max_tp
	tp_bar.value = tp
	
	speed = speed
	max_speed = max_speed
	
	
