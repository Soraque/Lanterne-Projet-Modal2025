extends Button

@export var duree_fermeture: float = 0.12

var tween_fermeture: Tween


func _ready() -> void:
	# Le bouton doit rester actif pendant la pause.
	process_mode = Node.PROCESS_MODE_ALWAYS

	pressed.connect(fermer_fenetre)


func fermer_fenetre() -> void:
	# Empêche plusieurs clics pendant l'animation.
	if not disabled:
		disabled = true

	var fenetre := get_parent().get_parent().get_parent().get_parent()

	tween_fermeture = fenetre.create_tween()
	tween_fermeture.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_fermeture.set_parallel(true)

	tween_fermeture.tween_property(
		fenetre,
		"modulate:a",
		0.0,
		duree_fermeture
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween_fermeture.tween_property(
		fenetre,
		"position",
		fenetre.position + Vector2(0, 12),
		duree_fermeture
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	await tween_fermeture.finished

	fenetre.hide()

	# Réinitialise la fenêtre pour sa prochaine apparition.
	fenetre.modulate.a = 1.0
	fenetre.position = fenetre.position - Vector2(0, 12)

	# Réactive le bouton pour la prochaine ouverture.
	disabled = false

	# Relance le jeu.
	get_tree().paused = false
