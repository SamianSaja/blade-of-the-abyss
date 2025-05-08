extends Control

@export var target_scene_path: String

func _ready():
	$FadeRect.visible = true
	$FadeRect.modulate.a = 1.0

	await fade_in()  # Fade masuk dari hitam ke transparan

	$HBoxContainer/AnimatedSprite2D.play("kyle-loading-screen")

	await get_tree().create_timer(2.0).timeout

	await fade_out()  # Fade keluar ke hitam

	var target_scene = load(target_scene_path)
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)

	queue_free()


func fade_in() -> Signal:
	var fade = $FadeRect
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.5)  # 0.5 detik dari hitam ke transparan
	return tween.finished


func fade_out() -> Signal:
	var fade = $FadeRect
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)  # 0.5 detik ke hitam
	return tween.finished
