# game_manager.gd
extends Node

var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene: String = ""
var has_respawn_point: bool = false


func set_respawn_point(pos: Vector2, scene_path: String) -> void:
	respawn_position = pos
	respawn_scene = scene_path
	has_respawn_point = true
