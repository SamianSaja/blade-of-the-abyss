extends Node

@onready var dialog_box_scene = preload("res://scenes/ui/DialogBox.tscn")
var dialog_box: CanvasLayer

signal dialog_finished

func _ready():
	dialog_box = dialog_box_scene.instantiate()
	add_child(dialog_box)
	dialog_box.hide()
	dialog_box.connect("dialog_finished", Callable(self, "_on_dialog_finished"))

func play_story_if_any(world_name: String):
	var story_path = "res://scripts/data/story/%s_intro.json" % world_name
	if FileAccess.file_exists(story_path):
		var file = FileAccess.open(story_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Array:
			dialog_box.visible = true
			dialog_box.start_dialog(json)

			# Sembunyikan semua UI player
			if get_parent().player_instance:
				var ui_nodes := [
					get_parent().player_instance.get_node_or_null("Joystick"),
					get_parent().player_instance.get_node_or_null("AttackController"),
					get_parent().player_instance.get_node_or_null("SkillOneButton"),
					get_parent().player_instance.get_node_or_null("SkillTwoButton"),
					get_parent().player_instance.get_node_or_null("SkillThreeButton"),
					get_parent().player_instance.get_node_or_null("SkillFourButton"),
					get_parent().player_instance.get_node_or_null("SkillUltimateButton"),
					get_parent().player_instance.get_node_or_null("DefendButton")
				]
				for ui in ui_nodes:
					if ui:
						ui.visible = false

			get_tree().paused = true  # Pause game saat dialog

func _on_dialog_finished():
	get_tree().paused = false
	
	# Tampilkan kembali semua UI player
	if get_parent().player_instance:
		var ui_nodes := [
			get_parent().player_instance.get_node_or_null("Joystick"),
			get_parent().player_instance.get_node_or_null("AttackController"),
			get_parent().player_instance.get_node_or_null("SkillOneButton"),
			get_parent().player_instance.get_node_or_null("SkillTwoButton"),
			get_parent().player_instance.get_node_or_null("SkillThreeButton"),
			get_parent().player_instance.get_node_or_null("SkillFourButton"),
			get_parent().player_instance.get_node_or_null("SkillUltimateButton"),
			get_parent().player_instance.get_node_or_null("DefendButton")
		]
		for ui in ui_nodes:
			if ui:
				ui.visible = true
	
	emit_signal("dialog_finished")
