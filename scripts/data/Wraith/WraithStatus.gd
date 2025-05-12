extends Node

# Status Boss
var max_hp: int = 500
var hp: int = 500

var max_mp: int = 200
var mp: int = 200

var max_tp: int = 100
var tp: int = 0

var summon_scene: PackedScene = preload("res://scenes/characters/EnemyGoblin.tscn")
# Batasan summon
var summon_cost: int = 200  # MP yang dibutuhkan untuk summon
var max_summons: int = 3 

# Untuk referensi ke healthbar atau UI boss (optional)
var status_wraith = Control

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
		status_wraith.set_status(hp, max_hp, mp, max_mp)
		#print(status_wraith, "status")

func perform_summon(parent: Node, position: Vector3, count: int = 1):
	if not status_wraith:
		print("Enemy status tidak tersedia.")
		return

	#if status_wraith.mp < summon_cost:
		#print("MP tidak cukup untuk summon.")
		#return

	if not summon_scene:
		print("Scene goblin tidak tersedia.")
		return

	# Kurangi MP
	consume_mana(summon_cost)

	for i in range(min(count, max_summons)):
		var summon_instance = summon_scene.instantiate()
		if summon_instance:
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			summon_instance.global_transform.origin = position + offset
			parent.add_child(summon_instance)
