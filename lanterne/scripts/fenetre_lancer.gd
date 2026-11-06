extends Panel

@export var duree_animation: float = 0.18
@export var decalage_vertical: float = 20.0

var position_finale: Vector2
var tween_animation: Tween


func _ready() -> void:
	# La fenêtre ne doit pas bloquer le jeu au démarrage.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func afficher() -> void:
	# Évite de relancer l'animation si la fenêtre est déjà ouverte.
	if visible:
		return

	# Met le jeu en pause.
	get_tree().paused = true

	# Affiche la fenêtre.
	show()

	# Mémorise sa position finale.
	position_finale = position

	# Prépare l'animation.
	modulate.a = 0.0
	position = position_finale + Vector2(0, decalage_vertical)

	# Joue l'animation.
	if tween_animation and tween_animation.is_running():
		tween_animation.kill()

	tween_animation = create_tween()
	tween_animation.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween_animation.set_parallel(true)
	tween_animation.tween_property(
		self,
		"position",
		position_finale,
		duree_animation
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween_animation.tween_property(
		self,
		"modulate:a",
		1.0,
		duree_animation
	)
