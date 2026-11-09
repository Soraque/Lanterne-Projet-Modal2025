extends CanvasLayer

# Chemin de la scène à charger lors du clic sur Start
const LVL1_SCENE_PATH := "res://scenes/lvls/lvl_3.tscn"

@onready var start_button: Button = $Fenetre_dash/Disposition/VBoxContainer/VBoxContainer/Button


func _ready() -> void:
	# Donne le focus UI au premier bouton dès le lancement du menu
	start_button.grab_focus()
	# Crée un calque par-dessus tout pour l'UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	# Crée un rectangle noir couvrant tout l'écran, totalement opaque au départ (alpha = 1.0)
	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 1.0)
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(color_rect)
	
	# Fait un fondu pour l'éclaircir (passer l'alpha de 1.0 à 0.0)
	var tween = canvas_layer.create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# Nettoie le ColorRect une fois le fondu terminé pour ne plus bloquer les clics
	await tween.finished
	canvas_layer.queue_free()

func _on_start_pressed() -> void:
	# Change la scène vers le niveau 1
	get_tree().change_scene_to_file(LVL1_SCENE_PATH)


func _on_settings_pressed() -> void:
	# Ajoute ici la logique pour ouvrir le menu d'options (ex: afficher un panneau Settings)
	print("Bouton Settings pressé")


func _on_exit_pressed() -> void:
	# Quitte le jeu
	get_tree().quit()
