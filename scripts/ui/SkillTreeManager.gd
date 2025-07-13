extends Node

# Skill data structure
var skill_data = {
	"basic_skills": [
		{
			"id": "basic_attack",
			"name": "Basic Attack",
			"description": "A basic sword attack",
			"level_required": 1,
			"coin_cost": 0,
			"unlocked": true
		},
		{
			"id": "defend",
			"name": "Defend",
			"description": "Block incoming damage",
			"level_required": 2,
			"coin_cost": 100,
			"unlocked": false
		},
		{
			"id": "skill_one",
			"name": "Slash Attack",
			"description": "A powerful slash attack",
			"level_required": 3,
			"coin_cost": 200,
			"unlocked": false
		}
	],
	"advanced_skills": [
		{
			"id": "skill_two",
			"name": "Broken Slash",
			"description": "A devastating broken slash attack",
			"level_required": 5,
			"coin_cost": 500,
			"unlocked": false
		},
		{
			"id": "skill_three",
			"name": "Shadow Dash",
			"description": "Quick dash with shadow effect",
			"level_required": 7,
			"coin_cost": 800,
			"unlocked": false
		},
		{
			"id": "skill_four",
			"name": "Searing Blade",
			"description": "A powerful searing attack",
			"level_required": 10,
			"coin_cost": 1000,
			"unlocked": false
		}
	],
	"ultimate_skills": [
		{
			"id": "skill_ultimate",
			"name": "Ultimate Slash",
			"description": "The most powerful attack",
			"level_required": 15,
			"coin_cost": 2000,
			"unlocked": false
		}
	]
}

var skill_tree_scene: Control
var player_level: int = 1
var player_coins: int = 0

func _ready():
	skill_tree_scene = load("res://scenes/ui/SkillTree.tscn").instantiate()
	populate_skill_tree()

func populate_skill_tree():
	# Clear existing skills
	for category in ["BasicSkills", "AdvancedSkills", "UltimateSkills"]:
		var grid = skill_tree_scene.get_node("SkillContainer/VBoxContainer/" + category + "/SkillGrid")
		for child in grid.get_children():
			child.queue_free()
	
	# Populate basic skills
	populate_skill_category("basic_skills", "BasicSkills")
	
	# Populate advanced skills
	populate_skill_category("advanced_skills", "AdvancedSkills")
	
	# Populate ultimate skills
	populate_skill_category("ultimate_skills", "UltimateSkills")

func populate_skill_category(category_key: String, node_name: String):
	var grid = skill_tree_scene.get_node("SkillContainer/VBoxContainer/" + node_name + "/SkillGrid")
	
	for skill in skill_data[category_key]:
		var skill_button = create_skill_button(skill)
		grid.add_child(skill_button)

func create_skill_button(skill_data: Dictionary) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 200)
	
	# Create container for skill info
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Add name
	var name_label = Label.new()
	name_label.text = skill_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_label)
	
	# Add requirements
	var req_label = Label.new()
	req_label.text = "Level: %d\nCost: %d coins" % [skill_data.level_required, skill_data.coin_cost]
	req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(req_label)
	
	# Add description
	var desc_label = Label.new()
	desc_label.text = skill_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)
	
	# Set button state
	update_button_state(button, skill_data)
	
	# Connect button press
	button.pressed.connect(func(): on_skill_button_pressed(skill_data))
	
	button.add_child(container)
	return button

func update_button_state(button: Button, skill_data: Dictionary):
	if skill_data.unlocked:
		button.text = "Unlocked"
		button.disabled = true
	elif player_level >= skill_data.level_required and player_coins >= skill_data.coin_cost:
		button.text = "Unlock"
		button.disabled = false
	else:
		button.text = "Locked"
		button.disabled = true

func on_skill_button_pressed(skill_data: Dictionary):
	if player_level >= skill_data.level_required and player_coins >= skill_data.coin_cost:
		# Deduct coins
		player_coins -= skill_data.coin_cost
		
		# Unlock skill
		skill_data.unlocked = true
		
		# Update UI
		populate_skill_tree()
		
		# Notify game about unlocked skill
		unlock_skill(skill_data.id)

func unlock_skill(skill_id: String):
	# This function will be called when a skill is unlocked
	# You can implement the actual skill unlocking logic here
	print("Unlocked skill: ", skill_id)
	
	# Example: Enable the skill in the player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		match skill_id:
			"defend":
				player.defend_button.visible = true
			"skill_one":
				player.skill_one_button.visible = true
			"skill_two":
				player.skill_two_button.visible = true
			"skill_three":
				player.skill_three_button.visible = true
			"skill_four":
				player.skill_four_button.visible = true
			"skill_ultimate":
				player.skill_ultimate_button.visible = true

func update_player_stats(level: int, coins: int):
	player_level = level
	player_coins = coins
	populate_skill_tree() 
