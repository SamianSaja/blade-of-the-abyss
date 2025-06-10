extends Node

@onready var camera = $Camera
@onready var dialog_box = $DialogBox
@onready var dialog_panel = $DialogBox/Panel
@onready var kyle = $CharacterRoot/KyleModel
@onready var kyle_animation = $CharacterRoot/KyleModel/AnimationPlayer
@onready var loading_screen = $LoadingScreen

var character_name = "world_1"

func _ready():
	dialog_panel.hide()
	start_cinematic()


func start_cinematic() -> void:
	var dialog_data = load_dialog_json(character_name)
	if dialog_data:

		await get_tree().create_timer(0.5).timeout
		loading_screen.fade_in()
		await get_tree().create_timer(1.0).timeout
		loading_screen.fade_out()

		await move_camera_to(kyle.global_position)
		kyle_animation.play("idle")
		dialog_panel.show()
		await dialog_box.start_dialog(dialog_data)
		dialog_box.dialog_finished.connect(_on_dialog_finished)
	else:
		print("Gagal memuat data dialog untuk:", character_name)


func load_dialog_json(name: String) -> Array:
	var path = "res://scripts/data/story/%s_intro.json" % name
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.parse_string(content)
		if typeof(json) == TYPE_ARRAY:
			return json
		else:
			push_error("File JSON harus berupa array.")
	else:
		push_error("Tidak bisa membuka file: %s" % path)
	return []


func move_camera_to(target_position: Vector3) -> Signal:
	var offset = Vector3(0, 12, 9)
	var camera_position = target_position + offset

	var tween = get_tree().create_tween()
	tween.tween_property(camera, "global_position", camera_position, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Tunggu kamera sampai pindah posisi dulu
	await tween.finished

	# Lalu arahkan kamera ke Kyle
	camera.look_at(target_position + Vector3(0, 1.5, 0), Vector3.UP)
	return tween.finished

func _on_dialog_finished():
	print("Dialog selesai. Lanjutkan ke scene berikut atau animasi lain.")
	queue_free()
