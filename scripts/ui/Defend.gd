extends TouchScreenButton

signal defend_held    # Ganti dari 'defend_buffered'
signal defend_pressed 

var _pressed_last_frame: bool = false

func _process(_delta):
	if is_pressed():
		emit_signal("defend_held")  # Dikirim setiap frame selama tombol ditekan
		if not _pressed_last_frame:
			emit_signal("defend_pressed")  # Hanya sekali saat pertama ditekan
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false
