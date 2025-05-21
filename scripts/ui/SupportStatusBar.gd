extends CanvasLayer

@onready var hp_bar = $MarginContainer/VBoxContainer/HpBar
@onready var mp_bar = $MarginContainer/VBoxContainer/MpBar
@onready var tp_bar = $MarginContainer/VBoxContainer/TpBar

# Komentar dulu sampai node tersedia di scene
# @onready var level_label = $MarginContainer/VBoxContainer/LevelLabel
# @onready var exp_bar = $MarginContainer/VBoxContainer/ExpBar
# @onready var power_label = $MarginContainer/VBoxContainer/PowerLabel
# @onready var magic_label = $MarginContainer/VBoxContainer/MagicLabel
# @onready var defense_label = $MarginContainer/VBoxContainer/DefenseLabel
# @onready var speed_label = $MarginContainer/VBoxContainer/SpeedLabel

func set_status(
		hp: int,
		max_hp: int,
		mp: int,
		max_mp: int,
		tp: int,
		max_tp: int,
		speed: int,
		power: int,
		magic: int,
		defense: int,
		level: int,
		exp: int,
		exp_to_next_level: int
	):
	# Bar utama
	hp_bar.max_value = max_hp
	hp_bar.value = hp

	mp_bar.max_value = max_mp
	mp_bar.value = mp

	tp_bar.max_value = max_tp
	tp_bar.value = tp

	# Komentar karena belum tersedia di scene
	# if exp_bar:
	# 	exp_bar.max_value = exp_to_next_level
	# 	exp_bar.value = exp

	# if level_label:
	# 	level_label.text = "Lv. %d" % level

	# if power_label:
	# 	power_label.text = "Power: %d" % power

	# if magic_label:
	# 	magic_label.text = "Magic: %d" % magic

	# if defense_label:
	# 	defense_label.text = "Defense: %d" % defense

	# if speed_label:
	# 	speed_label.text = "Speed: %d" % speed
