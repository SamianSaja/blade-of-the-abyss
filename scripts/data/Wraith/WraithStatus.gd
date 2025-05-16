extends Node

# === STATUS DASAR ===
var max_hp: int = 500
var hp: int = max_hp

var max_mp: int = 200
var mp: int = max_mp

var max_tp: int = 100
var tp: int = 0

var self_damage: int = 0

# === OPSIONAL: Referensi ke UI bar / status bar boss ===
var wraith_status_ui: Control = null

# === SETTER UNTUK UI STATUS BAR ===
func set_wraith_status(ui_status_node: Control) -> void:
	wraith_status_ui = ui_status_node
	update_status()

# === FUNGSI UTAMA ===
func take_damage(amount: int) -> void:
	self_damage = amount
	hp = clamp(hp - amount, 0, max_hp)
	update_status()

func heal(amount: int) -> void:
	hp = clamp(hp + amount, 0, max_hp)
	update_status()

func consume_mana(amount: int) -> void:
	mp = clamp(mp - amount, 0, max_mp)
	update_status()

func gain_mana(amount: int) -> void:
	mp = clamp(mp + amount, 0, max_mp)
	update_status()

func consume_tp(amount: int) -> void:
	tp = clamp(tp - amount, 0, max_tp)
	update_status()

func gain_tp(amount: int) -> void:
	tp = clamp(tp + amount, 0, max_tp)
	update_status()

func is_dead() -> bool:
	return hp <= 0

# === UPDATE UI STATUS BAR JIKA TERSEDIA ===
func update_status() -> void:
	if wraith_status_ui and wraith_status_ui.has_method("set_status"):
		wraith_status_ui.set_status(hp, max_hp, mp, max_mp, tp, max_tp)
