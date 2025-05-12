# player_status
extends Node

# Status Player
var max_hp: int = 100
var hp: int = 100

var status_bar: Control

func set_status(status):
	status_bar = status
	update_status()

func take_damage(amount: int):
	hp = clamp(hp - amount, 0, max_hp)
	update_status()

func is_dead() -> bool:
	return hp <= 0

func update_status():
	if status_bar and status_bar.has_method("set_status"):
		status_bar.set_status(hp, max_hp)
