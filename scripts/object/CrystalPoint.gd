extends Node3D

@onready var save_area: Area3D = $SaveArea
@onready var save_prompt: Label = $SavePrompt
@onready var red_ring_effect: Node3D = $RedRingEffect

var player_in_range: bool = false
var player_node: Node3D = null
var save_cooldown: float = 0.0
var save_cooldown_duration: float = 2.0  # 2 detik cooldown
var attack_button: TouchScreenButton = null

# Store original textures
var original_normal_texture: Texture2D
var original_pressed_texture: Texture2D

# Push button textures
var push_button_normal: Texture2D
var push_button_pressed: Texture2D

func _ready():
	# Connect area signals
	save_area.body_entered.connect(_on_save_area_body_entered)
	save_area.body_exited.connect(_on_save_area_body_exited)
	
	# Set collision shape
	var collision_shape = save_area.get_node("CollisionShape3D")
	if not collision_shape.shape:
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 3.0  # Radius 3 unit untuk area save
		collision_shape.shape = sphere_shape
	
	# Load push button textures
	push_button_normal = preload("res://assets/ui/push-button.png")
	push_button_pressed = preload("res://assets/ui/push-button-pressed.png")

func _process(delta):
	# Update cooldown
	if save_cooldown > 0:
		save_cooldown -= delta
	
	# Update save prompt visibility
	if player_in_range and player_node:
		save_prompt.visible = true
		
		# Check if player pressed attack button (keyboard input)
		if Input.is_action_just_pressed("basic_attack") and save_cooldown <= 0:
			save_game()
	else:
		save_prompt.visible = false

func _on_save_area_body_entered(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = true
		player_node = body
		print("Player entered save area")
		
		# Try to find the attack button in the player
		find_attack_button()
		
		# Change button appearance to push button
		change_to_push_button()

func _on_save_area_body_exited(body: Node3D):
	if body.is_in_group("player"):
		player_in_range = false
		player_node = null
		
		# Restore original button appearance
		restore_original_button()
		
		attack_button = null
		print("Player exited save area")

func find_attack_button():
	if not player_node:
		return
	
	# Look for AttackController in player's children
	for child in player_node.get_children():
		if child is TouchScreenButton and child.has_signal("attack_pressed"):
			attack_button = child
			# Connect to save_pressed signal instead of attack_pressed
			if attack_button.has_signal("save_pressed"):
				attack_button.save_pressed.connect(_on_save_button_pressed)
			print("Attack button found and connected")
			break

func change_to_push_button():
	if not attack_button:
		return
	
	# Store original textures if not already stored
	if not original_normal_texture:
		original_normal_texture = attack_button.texture_normal
		original_pressed_texture = attack_button.texture_pressed
	
	# Change to push button textures
	attack_button.texture_normal = push_button_normal
	attack_button.texture_pressed = push_button_pressed
	
	# Set button to save mode
	if attack_button.has_method("set_save_mode"):
		attack_button.set_save_mode(true)
	
	print("Button changed to push button appearance and save mode")

func restore_original_button():
	if not attack_button or not original_normal_texture:
		return
	
	# Restore original textures
	attack_button.texture_normal = original_normal_texture
	attack_button.texture_pressed = original_pressed_texture
	
	# Set button back to attack mode
	if attack_button.has_method("set_save_mode"):
		attack_button.set_save_mode(false)
	
	print("Button restored to original appearance and attack mode")

func _on_save_button_pressed():
	if player_in_range and save_cooldown <= 0:
		save_game()

func save_game():
	if not player_node:
		return
	
	# Get game instance
	var game_instance = get_tree().current_scene
	if not game_instance or not game_instance.has_method("save_game_at_crystal"):
		print("Error: Game instance not found or save method not available")
		return
	
	# Try to save
	if game_instance.save_game_at_crystal():
		print("Game saved successfully at Crystal Point!")
		save_cooldown = save_cooldown_duration
		
		# Visual feedback
		show_save_success()
	else:
		print("Failed to save game!")

func show_save_success():
	# Change text temporarily
	var original_text = save_prompt.text
	save_prompt.text = "Game Saved!"
	save_prompt.modulate = Color.GREEN
	
	# Create timer to restore original text
	var timer = get_tree().create_timer(2.0)
	await timer.timeout
	
	save_prompt.text = original_text
	save_prompt.modulate = Color.WHITE 