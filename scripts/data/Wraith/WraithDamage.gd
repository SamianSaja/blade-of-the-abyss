extends Node

# Damage boss magic attack
var magic_attack_damage: int = 25
var ultimate_magic_damage: int = 60

# Preload skill scenes
var tornado_scene: PackedScene = preload("res://scenes/characters/Effects/WraithTornadoSkill.tscn")
var summon_scene: PackedScene = preload("res://scenes/characters/EnemyGoblin.tscn")

# MP cost dan batas summon
var summon_cost: int = 20
var max_summons: int = 3
var active_summons: Array = []

# Referensi ke wraith status dan player
var wraith_status = null
var player: Node3D = null

# Cooldown tornado (dalam detik)
var tornado_cooldown: float = 8.0
var tornado_on_cooldown: bool = false


# Setter
func set_wraith_status(status_node):
	wraith_status = status_node

func set_player_reference(player_node):
	player = player_node

# Damage Utility
func deal_damage_to_self(damage: int):
	if wraith_status:
		wraith_status.take_damage(damage)

func deal_damage_to_target(target, damage: int):
	if target and target.has_method("take_damage"):
		target.take_damage(damage)

# === SKILL FUNCTIONS ===

func perform_magic_attack(target):
	deal_damage_to_target(target, magic_attack_damage)

func perform_ultimate_magic(target):
	deal_damage_to_target(target, ultimate_magic_damage)

func perform_tornado_skill():
	if tornado_on_cooldown:
		print("Tornado masih cooldown.")
		return

	if not is_instance_valid(player):
		print("Player tidak valid untuk tornado.")
		return

	if not tornado_scene:
		print("Scene tornado tidak tersedia.")
		return

	var tornado_instance = tornado_scene.instantiate()
	get_tree().current_scene.add_child(tornado_instance)
	tornado_instance.start_skill(player.global_transform.origin)

	# Mulai cooldown
	start_tornado_cooldown()

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

	# Batas jumlah summon
	if active_summons.size() >= max_summons:
		print("Jumlah summon maksimal tercapai.")
		return

	var summonable_count = min(count, max_summons - active_summons.size())

	# Kurangi MP satu kali untuk seluruh batch
	wraith_status.consume_mana(summon_cost)

	for i in range(summonable_count):
		var summon_instance = summon_scene.instantiate()
		if summon_instance:
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			summon_instance.global_transform.origin = position + offset
			parent.add_child(summon_instance)

			active_summons.append(summon_instance)

			# Hapus dari list jika keluar dari tree (mati)
			summon_instance.tree_exited.connect(func():
				if summon_instance in active_summons:
					active_summons.erase(summon_instance)
			)

# cooldown config
func start_tornado_cooldown():
	tornado_on_cooldown = true

	await get_tree().create_timer(tornado_cooldown).timeout

	tornado_on_cooldown = false
	print("Tornado skill siap digunakan lagi.")
