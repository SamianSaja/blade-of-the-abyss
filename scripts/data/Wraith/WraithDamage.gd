# enemy_damage.gd
extends Node

# Damage boss magic attack
var magic_attack_damage: int = 25
var ultimate_magic_damage: int = 60

# Referensi ke node status (enemy_status.gd)
var enemy_status = null

func set_enemy_status(status_node):
	enemy_status = status_node

func deal_damage_to_self(damage: int):
	if enemy_status:
		enemy_status.take_damage(damage)

func deal_damage_to_target(target, damage: int):
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

# Skill boss
func perform_magic_attack(target):
	deal_damage_to_target(target, magic_attack_damage)

func perform_ultimate_magic(target):
	deal_damage_to_target(target, ultimate_magic_damage)
