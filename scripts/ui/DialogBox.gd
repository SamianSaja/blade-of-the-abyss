extends CanvasLayer

signal dialog_finished

var dialog_data = []
var current_index = 0

@onready var speaker_label = $Panel/SpeakerLabel
@onready var dialog_text = $Panel/DialogText
@onready var next_button = $Panel/NextButton

var typing = false
var full_text = ""
var typing_index = 0
var typing_speed = 0.02  # Kecepatan animasi huruf (dalam detik)

func _ready():
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	next_button.pressed.connect(_on_next_button_pressed)

func start_dialog(data: Array):
	dialog_data = data
	current_index = 0
	show_dialog_line()
	show()

func show_dialog_line():
	if current_index >= dialog_data.size():
		emit_signal("dialog_finished")
		hide()
		return
	
	var entry = dialog_data[current_index]
	speaker_label.text = entry.get("speaker", "")
	full_text = entry.get("text", "")
	dialog_text.text = ""
	typing = true
	typing_index = 0
	current_index += 1
	# Start typing animation
	animate_text()

func animate_text():
	if typing_index < full_text.length():
		dialog_text.text += full_text[typing_index]
		typing_index += 1
		await get_tree().create_timer(typing_speed).timeout
		if typing:
			animate_text()
	else:
		typing = false

func _on_next_button_pressed() -> void:
	if typing:
		typing = false
		dialog_text.text = full_text
	else:
		show_dialog_line()
