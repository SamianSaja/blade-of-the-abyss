extends TextureButton

signal skill_one_buffered  # Emit tiap kali tombol ditekan (sekali per tekan)

var _pressed_last_frame: bool = false

func _process(_delta):
	if is_pressed():
		if not _pressed_last_frame:
			emit_signal("skill_one_buffered")
			_pressed_last_frame = true
	else:
		_pressed_last_frame = false
