extends Camera3D

@export var player_path: NodePath

# TODO: configuration limit kamera tiap world
@export var min_x: float = -15.0
@export var max_x: float = 50.0
@export var min_z: float = -15.0
@export var max_z: float = 45.0
@export var fixed_y: float = 15.0

var player: Node3D

func _ready():
	if player_path != NodePath(""):
		player = get_node(player_path)

func _process(delta):
	if not player:
		return

	var target_pos = player.global_position
	target_pos.x = clamp(target_pos.x, min_x, max_x)
	target_pos.z = clamp(target_pos.z, min_z, max_z)
	target_pos.y = fixed_y

	target_pos.z += 5
	global_position = target_pos
