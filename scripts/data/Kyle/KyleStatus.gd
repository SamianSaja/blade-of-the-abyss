extends Node

# ==================== Basic Resources ====================
var hp: int = 200
var mp: int = 100
var tp: int = 100

var max_hp: int = 200
var max_mp: int = 100
var max_tp: int = 100

# ==================== Core Stats ====================
var power: int = 10
var magic: int = 10
var defense: int = 5
var speed: int = 7
var acceleration: int = 20

# ==================== Leveling ====================
var level: int = 1
var exp: int = 0
var exp_to_next_level: int = 100

# ==================== UI Reference ====================
var player_status_bar: CanvasLayer

var self_damage: int = 0


# ==================== Setter ====================
func set_player_status(player_status):
	player_status_bar = player_status
	update_status_player()


# ==================== Combat Mechanics ====================
func take_damage(amount: int):
	var reduced_damage = max(amount - defense, 1)
	self_damage = reduced_damage
	hp = clamp(hp - reduced_damage, 0, max_hp)
	update_status_player()

func heal(amount: int):
	hp = clamp(hp + amount, 0, max_hp)
	update_status_player()

func consume_mana(amount: int):
	mp = clamp(mp - amount, 0, max_mp)
	update_status_player()

func gain_mana(amount: int):
	mp = clamp(mp + amount, 0, max_mp)
	update_status_player()

func consume_tp(amount: int):
	tp = clamp(tp - amount, 0, max_tp)
	update_status_player()

func gain_tp(amount: int):
	tp = clamp(tp + amount, 0, max_tp)
	update_status_player()


# ==================== Leveling & Experience ====================
func gain_exp(amount: int):
	exp += amount
	while exp >= exp_to_next_level:
		exp -= exp_to_next_level
		level_up()

	update_status_player()

func level_up():
	level += 1
	exp_to_next_level += int(exp_to_next_level * 0.2) # 20% lebih sulit tiap level

	# Naikkan stats
	max_hp += 20
	max_mp += 10
	power += 2
	magic += 2
	defense += 1
	speed += 1

	# Pulihkan
	hp = max_hp
	mp = max_mp
	tp = max_tp

	print("Level Up! Level sekarang:", level)
	update_status_player()


# ==================== Info & UI ====================
func is_dead() -> bool:
	return hp <= 0

func update_status_player():
	if player_status_bar and player_status_bar.has_method("set_status"):
		player_status_bar.set_status(
			hp, max_hp,
			mp, max_mp,
			tp, max_tp,
			speed,
			power, magic, defense,
			level, exp, exp_to_next_level
		)
