extends TouchScreenButton

signal attack_buffered  # Emit tiap kali tombol ditekan (sekali per tekan)
signal attack_pressed 
signal save_pressed  # Signal khusus untuk save game

var _pressed_last_frame: bool = false
var is_save_mode: bool = false  # Flag untuk mode save

func _process(_delta):
	if is_pressed():
		if not _pressed_last_frame:
			if is_save_mode:
				emit_signal("save_pressed")
			else:
				emit_signal("attack_pressed")
				emit_signal("attack_buffered")
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false

# Function to switch between attack and save mode
func set_save_mode(enabled: bool):
	is_save_mode = enabled
