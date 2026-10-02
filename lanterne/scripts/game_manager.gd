# game_manager.gd
extends Node

var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene: String = ""
var has_respawn_point: bool = false
var vitJ : Vector2 = Vector2.ZERO
var Changinglvl = false
var changepos : Vector2

# Conservation de l'état de la lanterne
var lantern_usure_saved: float = 100.0
var is_lanterne_saved: bool = true

# Liste des identifiants uniques des feux de camp allumés
var active_checkpoints: Array[String] = []


func set_respawn_point(pos: Vector2, scene_path: String) -> void:
	respawn_position = pos
	respawn_scene = scene_path
	has_respawn_point = true


func register_checkpoint(checkpoint_id: String) -> void:
	if not active_checkpoints.has(checkpoint_id):
		active_checkpoints.append(checkpoint_id)


func is_checkpoint_active(checkpoint_id: String) -> bool:
	return active_checkpoints.has(checkpoint_id)
