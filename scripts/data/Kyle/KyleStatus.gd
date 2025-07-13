extends Node

# ==================== Basic Resources ====================
var hp: int = 500
var mp: int = 200
var tp: int = 100

var max_hp: int = 500
var max_mp: int = 200
var max_tp: int = 100

# ==================== Core Stats ====================
var power: int = 10
var magic: int = 10
var defense: int = 5
var speed: int = 7
var acceleration: int = 20

# ==================== Buff Stats ====================
var base_speed: int = 7
var base_defense: int = 5
var speed_buff_timer: float = 0.0
var defense_buff_timer: float = 0.0
var speed_buff_duration: float = 10.0  # 10 detik
var defense_buff_duration: float = 15.0  # 15 detik
var speed_buff_multiplier: float = 1.5  # 50% peningkatan speed
var defense_buff_multiplier: float = 2.0  # 100% peningkatan defense

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

# ==================== Buff Functions ====================
func apply_speed_buff():
	speed_buff_timer = speed_buff_duration
	speed = int(base_speed * speed_buff_multiplier)
	print("Speed buff applied! Speed: ", speed)
	update_status_player()

func apply_defense_buff():
	defense_buff_timer = defense_buff_duration
	defense = int(base_defense * defense_buff_multiplier)
	print("Defense buff applied! Defense: ", defense)
	update_status_player()

func update_buffs(delta: float):
	# Update speed buff
	if speed_buff_timer > 0:
		speed_buff_timer -= delta
		if speed_buff_timer <= 0:
			speed = base_speed
			speed_buff_timer = 0.0
			print("Speed buff expired! Speed: ", speed)
			update_status_player()
	
	# Update defense buff
	if defense_buff_timer > 0:
		defense_buff_timer -= delta
		if defense_buff_timer <= 0:
			defense = base_defense
			defense_buff_timer = 0.0
			print("Defense buff expired! Defense: ", defense)
			update_status_player()

func get_speed_buff_remaining() -> float:
	return speed_buff_timer

func get_defense_buff_remaining() -> float:
	return defense_buff_timer

func is_speed_buffed() -> bool:
	return speed_buff_timer > 0

func is_defense_buffed() -> bool:
	return defense_buff_timer > 0


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
	base_defense += 1  # Update base defense juga

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
