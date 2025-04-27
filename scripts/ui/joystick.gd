extends Control
class_name Joystick

@export var joystick_radius: float = 100.0

@onready var knob: TextureRect = $Knob
@onready var base: TextureRect = $Base

var input_vector: Vector2 = Vector2.ZERO

func _ready():
	if not knob or not base:
		push_error("Joystick: 'Knob' atau 'Base' belum di-assign.")
		return

	# Pastikan posisi awal knob ada di tengah base
	reset_knob()

func _gui_input(event: InputEvent):
	if not knob or not base:
		return

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var base_center: Vector2 = base.global_position + (base.size / 2)
		var direction: Vector2 = event.position - base_center
		var distance: float = direction.length()
		var clamped: Vector2 = direction.normalized() * min(distance, joystick_radius)

		if event is InputEventScreenTouch and not event.pressed:
			# Lepas sentuhan
			reset_knob()
			input_vector = Vector2.ZERO
		else:
			knob.global_position = base_center + clamped - (knob.size / 2)
			input_vector = clamped / joystick_radius

func reset_knob():
	var base_center: Vector2 = base.global_position + (base.size / 2)
	knob.position = base_center - (knob.size / 2)
	input_vector = Vector2.ZERO

func get_input_vector() -> Vector2:
	return input_vector
