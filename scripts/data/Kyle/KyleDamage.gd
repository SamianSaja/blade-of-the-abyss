# player_damage.gd
extends Node

# Damage nilai default untuk berbagai serangan
var basic_attack_damage: int = 10
var skill_one_damage: int = 20
var skill_two_damage: int = 25
var skill_three_damage: int = 30
var skill_four_damage: int = 35
var ultimate_skill_damage: int = 50

# Untuk menghubungkan ke node status (player_status.gd)
var player_status = null

func set_player_status(status_node):
	player_status = status_node

func deal_damage_to_self(damage: int):
	if player_status:
		player_status.take_damage(damage)

func deal_damage_to_enemy(enemy, damage: int):
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)

# Contoh fungsi serangan
func perform_basic_attack(target):
	deal_damage_to_enemy(target, basic_attack_damage)

func perform_skill_one(target):
	if player_status:
		player_status.consume_mana(10)
	deal_damage_to_enemy(target, skill_one_damage)

func perform_skill_two(target):
	deal_damage_to_enemy(target, skill_two_damage)

func perform_skill_three(target):
	deal_damage_to_enemy(target, skill_three_damage)

func perform_skill_four():
	if player_status:
		player_status.consume_mana(20)
		#await player_status.gain_speed(3, 3.0)
	#deal_damage_to_enemy(target, skill_four_damage)

func perform_ultimate_skill(target):
	deal_damage_to_enemy(target, ultimate_skill_damage)

func perform_ultimate_attack(target):
	# Ultimate skill doesn't consume mana as it's a buff that lasts 30 seconds
	deal_damage_to_enemy(target, ultimate_skill_damage)
