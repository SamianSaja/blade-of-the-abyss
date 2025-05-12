# player_status
extends Node

# Status Player
var max_hp: int = 100
var hp: int = 100

var max_mp: int = 50
var mp: int = 50

var max_tp: int = 100
var tp: int = 50

var player_status_bar: CanvasLayer

func set_player_status(player_status):
	player_status_bar = player_status
	update_status_player()

func take_damage(amount: int):
	hp = clamp(hp - amount, 0, max_hp)
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

func is_dead() -> bool:
	return hp <= 0

func update_status_player():
	if player_status_bar and player_status_bar.has_method("set_status"):
		player_status_bar.set_status(hp, max_hp, mp, max_mp, tp, max_tp)
