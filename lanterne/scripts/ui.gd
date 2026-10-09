extends CanvasLayer

# Chemin de la scène à charger lors du clic sur Start
const LVL1_SCENE_PATH := "res://scenes/lvls/lvl_3.tscn"

@onready var start_button: Button = $VBoxContainer/Button

func _ready() -> void:
	# Donne le focus UI au premier bouton dès le lancement du menu
	start_button.grab_focus()


func _on_start_pressed() -> void:
	# Change la scène vers le niveau 1
	get_tree().change_scene_to_file(LVL1_SCENE_PATH)


func _on_settings_pressed() -> void:
	# Ajoute ici la logique pour ouvrir le menu d'options (ex: afficher un panneau Settings)
	print("Bouton Settings pressé")


func _on_exit_pressed() -> void:
	# Quitte le jeu
	get_tree().quit()
