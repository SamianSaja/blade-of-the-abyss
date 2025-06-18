extends Node

# ================== DAMAGE VALUES ==================
const MAGIC_ATTACK_DAMAGE: int = 25
const ULTIMATE_MAGIC_DAMAGE: int = 60

# ================== SUMMON CONFIG ==================
const SUMMON_COST: int = 20
const MAX_SUMMONS: int = 3
const SUMMON_COOLDOWN: float = 6.0
var active_summons: Array = []
var summon_on_cooldown: bool = false
var summon_scene: PackedScene = preload("res://scenes/characters/EnemyGoblin.tscn")

# ================== TORNADO CONFIG ==================
const TORNADO_COST: float = 5.0
const TORNADO_COOLDOWN: float = 8.0
const FULL_TORNADO_COOLDOWN: float = 16.0
var tornado_on_cooldown: bool = false
var full_tornado_on_cooldown: bool = false
var tornado_scene: PackedScene = preload("res://scenes/characters/Effects/WraithTornadoSkill.tscn")

# ================== REFERENCES ==================
var wraith_status: Node = null
var player: Node3D = null


# ================== SETTERS ==================
func set_wraith_status(status_node):
	wraith_status = status_node

func set_player_reference(player_node):
	player = player_node


# ================== DAMAGE HELPERS ==================
func deal_damage_to_self(damage: int):
	if wraith_status:
		wraith_status.take_damage(damage)

func deal_damage_to_target(target, damage: int):
	if target and target.has_method("take_damage"):
		target.take_damage(damage)


# ================== SKILL: MAGIC ATTACK ==================
func perform_magic_attack(target):
	deal_damage_to_target(target, MAGIC_ATTACK_DAMAGE)

func perform_ultimate_magic(target):
	deal_damage_to_target(target, ULTIMATE_MAGIC_DAMAGE)


# ================== SKILL: TORNADO ==================
func perform_tornado_skill():
	if tornado_on_cooldown:
		print("Tornado masih cooldown.")
		return

	if not is_instance_valid(owner.current_target):
		print("Target tidak valid untuk tornado.")
		return

	if not tornado_scene:
		print("Scene tornado tidak tersedia.")
		return
	
	if wraith_status.mp < TORNADO_COST:
		print("MP tidak cukup untuk tornado.")
		return
	
	wraith_status.consume_mana(TORNADO_COST)

	var tornado_instance = tornado_scene.instantiate()
	get_tree().current_scene.add_child(tornado_instance)
	tornado_instance.start_skill(owner.current_target.global_transform.origin)

	# Cooldown
	start_cooldown("tornado")

# ================== SKILL: FULL AREA TORNADO (ULTIMATE) ==================
func perform_full_tornado_skill(count: int = 5, radius: float = 10.0):
	if full_tornado_on_cooldown:
		print("Tornado masih cooldown.")
		return

	if not tornado_scene:
		print("Scene tornado tidak tersedia.")
		return
	
	if wraith_status.mp < TORNADO_COST * count:
		print("MP tidak cukup untuk full tornado.")
		return

	wraith_status.consume_mana(TORNADO_COST * count)

	var origin = owner.global_transform.origin # Posisi Wraith

	for i in range(count):
		var random_offset = Vector3(
			randf_range(-radius, radius),
			0,
			randf_range(-radius, radius)
		)
		var spawn_position = origin + random_offset

		var tornado_instance = tornado_scene.instantiate()
		get_tree().current_scene.add_child(tornado_instance)
		tornado_instance.start_skill_2(spawn_position)

		# Set pergerakan berkeliling (acak)
		if tornado_instance.has_method("set_random_movement"):
			tornado_instance.set_random_movement()
	
	start_cooldown("full_tornado")

# ================== SKILL: SUMMON ==================
func perform_summon(parent: Node, position: Vector3, count: int = 1):
	if summon_on_cooldown:
		print("Summon masih cooldown.")
		return

	if not wraith_status:
		print("Enemy status tidak tersedia.")
		return

	if wraith_status.mp < SUMMON_COST:
		print("MP tidak cukup untuk summon.")
		return

	if not summon_scene:
		print("Scene goblin tidak tersedia.")
		return

	if active_summons.size() >= MAX_SUMMONS:
		print("Jumlah summon maksimal tercapai.")
		return

	var summonable_count = min(count, MAX_SUMMONS - active_summons.size())

	wraith_status.consume_mana(SUMMON_COST)

	for i in range(summonable_count):
		var summon_instance = summon_scene.instantiate()
		if summon_instance:
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			summon_instance.global_transform.origin = position + offset
			parent.add_child(summon_instance)

			active_summons.append(summon_instance)

			summon_instance.tree_exited.connect(func():
				active_summons.erase(summon_instance)
			)

	# Cooldown
	start_cooldown("summon")


# ================== GENERIC COOLDOWN HANDLER ==================
func start_cooldown(skill_name: String):
	match skill_name:
		"tornado":
			tornado_on_cooldown = true
			await get_tree().create_timer(TORNADO_COOLDOWN).timeout
			tornado_on_cooldown = false
			print("Tornado skill siap digunakan lagi.")
		"full_tornado":
			full_tornado_on_cooldown = true
			await get_tree().create_timer(FULL_TORNADO_COOLDOWN).timeout
			full_tornado_on_cooldown = false
			print("Tornado skill siap digunakan lagi.")
		"summon":
			summon_on_cooldown = true
			await get_tree().create_timer(SUMMON_COOLDOWN).timeout
			summon_on_cooldown = false
			print("Summon skill siap digunakan lagi.")
