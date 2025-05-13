# player_status
extends Node

# Status Player
var hp: int = 200
var mp: int = 100
var tp: int = 100
var speed: int = 7
var acceleration: int = 20

var max_hp: int = 200
var max_mp: int = 100
var max_tp: int = 100
var max_speed: int = 100

var speed_timer := Timer.new()

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

#func gain_speed(amount: int, duration: float):
	#var original_speed = speed
	#speed += amount
	#update_status_player()
#
	#speed_timer.wait_time = duration
	#speed_timer.one_shot = true
	#speed_timer.timeout.connect(func():
		#speed = original_speed
		#update_status_player()
	#)
	#add_child(speed_timer)
	#speed_timer.start()


func is_dead() -> bool:
	return hp <= 0

func update_status_player():
	if player_status_bar and player_status_bar.has_method("set_status"):
		player_status_bar.set_status(hp, max_hp, mp, max_mp, tp, max_tp, speed, max_speed)
