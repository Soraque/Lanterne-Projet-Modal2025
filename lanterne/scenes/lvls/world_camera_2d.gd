extends Camera2D

@onready var target_camera: Camera2D = $"../../../PlayerLayer/player/Camera2D"

func _process(_delta: float) -> void:
	global_position = target_camera.global_position
	zoom = target_camera.zoom
	rotation = target_camera.rotation
