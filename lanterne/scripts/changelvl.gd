extends Area2D

@export var changecombien : int = 1
@export var fairesauterjoueur = false
var FILEBEGIN = "res://scenes/lvls/lvl_"

func _on_body_entered(body: Node2D) -> void:
	if fairesauterjoueur: 
		GameManager.PlayerJumpOnEnter = true
	var currentlvl = get_tree().current_scene.scene_file_path.to_int()
	var nextlvl = FILEBEGIN + str(currentlvl + changecombien) + ".tscn"
	get_tree().change_scene_to_file(nextlvl)
