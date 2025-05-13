# wraith_damage.gd
extends Node

# Damage boss magic attack
var magic_attack_damage: int = 25
var ultimate_magic_damage: int = 60

var summon_scene: PackedScene = preload("res://scenes/characters/EnemyGoblin.tscn")
# Batasan summon
var summon_cost: int = 20  # MP yang dibutuhkan untuk summon
var max_summons: int = 3
var active_summons := []

# Referensi ke node status (wraith_status.gd)
var wraith_status = null

func set_wraith_status(status_node):
	wraith_status = status_node

func deal_damage_to_self(damage: int):
	if wraith_status:
		wraith_status.take_damage(damage)

func deal_damage_to_target(target, damage: int):
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

# Skill boss
func perform_magic_attack(target):
	deal_damage_to_target(target, magic_attack_damage)

func perform_summon(parent: Node, position: Vector3, count: int = 1):
	if not wraith_status:
		print("Enemy status tidak tersedia.")
		return

	if wraith_status.mp < summon_cost:
		print("MP tidak cukup untuk summon.")
		return

	if not summon_scene:
		print("Scene goblin tidak tersedia.")
		return

	# Cek apakah masih bisa summon (berdasarkan jumlah yang masih aktif)
	if active_summons.size() >= max_summons:
		print("Jumlah summon maksimal tercapai.")
		return

	var summonable_count = min(count, max_summons - active_summons.size())

	# Kurangi MP
	wraith_status.consume_mana(summon_cost)

	for i in range(summonable_count):
		var summon_instance = summon_scene.instantiate()
		if summon_instance:
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			summon_instance.global_transform.origin = position + offset
			parent.add_child(summon_instance)

			# Tambahkan ke daftar summon aktif
			active_summons.append(summon_instance)

			# Hapus dari list saat mati (queue_free)
			summon_instance.tree_exited.connect(func():
				active_summons.erase(summon_instance)
			)


func perform_ultimate_magic(target):
	deal_damage_to_target(target, ultimate_magic_damage)
