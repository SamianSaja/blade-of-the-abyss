extends TouchScreenButton

signal pause_menu_button_buffered  # Emit tiap kali tombol ditekan (sekali per tekan)
signal pause_menu_button_pressed 

var _pressed_last_frame: bool = false

func _process(_delta):
	if is_pressed():
		if not _pressed_last_frame:
			emit_signal("pause_menu_button_pressed")
			emit_signal("pause_menu_button_buffered")
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false
