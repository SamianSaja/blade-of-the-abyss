extends TouchScreenButton

signal attack_buffered  # Emit tiap kali tombol ditekan (sekali per tekan)
signal attack_pressed 

var _pressed_last_frame: bool = false

func _process(_delta):
	if is_pressed():
		if not _pressed_last_frame:
			emit_signal("attack_pressed")
			emit_signal("attack_buffered")
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false
