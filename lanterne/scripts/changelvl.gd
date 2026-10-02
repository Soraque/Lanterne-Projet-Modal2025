extends Area2D

@export var changecombien : int = 1
@export var VitJ : Vector2
@export var PosJ : Vector2
var FILEBEGIN = "res://scenes/lvls/lvl_"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.Changinglvl = true
		GameManager.changepos = PosJ
		GameManager.vitJ = VitJ
		
		# Sauvegarde de la lanterne
		GameManager.lantern_usure_saved = body.lantern_usure
		GameManager.is_lanterne_saved = body.is_lanterne
		
		var currentlvl = get_tree().current_scene.scene_file_path.to_int()
		var nextlvl = FILEBEGIN + str(currentlvl + changecombien) + ".scn"
		get_tree().change_scene_to_file(nextlvl)
