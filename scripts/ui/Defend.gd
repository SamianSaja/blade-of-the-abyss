extends TouchScreenButton

signal defend_buffered  # Emit tiap kali tombol ditekan (sekali per tekan)
signal defend_pressed 

var _pressed_last_frame: bool = false

func _process(_delta):
	if is_pressed():
		if not _pressed_last_frame:
			emit_signal("defend_pressed")
			emit_signal("defend_buffered")
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false
