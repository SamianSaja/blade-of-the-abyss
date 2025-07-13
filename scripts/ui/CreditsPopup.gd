extends Control

func _ready():
	# Hide the popup initially
	visible = false
	
	# Connect the close button
	$Panel/VBoxContainer/TitleContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	
	# Connect escape key to close
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		_on_close_button_pressed()

func show_popup():
	visible = true
	$Panel/VBoxContainer/TitleContainer/CloseButton.grab_focus()

func _on_close_button_pressed():
	visible = false
	# Return focus to the main menu
	get_parent().get_node("VBoxContainer/CreditsContainer/CreditsButton").grab_focus() 
 
