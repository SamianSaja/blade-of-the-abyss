# altar_room/CameraLimits.gd
extends Node3D

var camera_limits_by_world = {
	"world_1": {
		"min_x": -10.0, "max_x": 30.0,
		"min_z": -5.0,  "max_z": 20.0,
		"fixed_y": 12.0
	},
	"world_2": {
		"min_x": -20.0, "max_x": 50.0,
		"min_z": -10.0, "max_z": 35.0,
		"fixed_y": 15.0
	},
	"altar_room": {
		"min_x": -5.0, "max_x": 25.0,
		"min_z": -5.0, "max_z": 25.0,
		"fixed_y": 18.0
	}
}
