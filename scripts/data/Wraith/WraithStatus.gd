# enemy_status.gd
extends Node

# Status Boss
var max_hp: int = 500
var hp: int = 500

var max_mp: int = 200
var mp: int = 200

var max_tp: int = 100
var tp: int = 0

# Untuk referensi ke healthbar atau UI boss (optional)
var status_wraith = null

func set_wraith_status(status):
	status_wraith = status
	update_status()

func take_damage(amount: int):
	hp = clamp(hp - amount, 0, max_hp)
	update_status()

func heal(amount: int):
	hp = clamp(hp + amount, 0, max_hp)
	update_status()

func consume_mana(amount: int):
	mp = clamp(mp - amount, 0, max_mp)
	update_status()

func gain_mana(amount: int):
	mp = clamp(mp + amount, 0, max_mp)
	update_status()

func consume_tp(amount: int):
	tp = clamp(tp - amount, 0, max_tp)
	update_status()

func gain_tp(amount: int):
	tp = clamp(tp + amount, 0, max_tp)
	update_status()

func is_dead() -> bool:
	return hp <= 0

func update_status():
	if status_wraith and status_wraith.has_method("set_status"):
		status_wraith.set_status(hp, max_hp, mp, max_mp, tp, max_tp)
