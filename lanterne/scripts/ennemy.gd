extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hb_coll: CollisionShape2D = $Killzone/CollisionShape2D

var is_angry = false

#Nombre de lumières actuellement présentes dans la zone de détection.
#Cela permet de ne calmer l'ennemi que lorsque toutes les lumières sont sorties.

var lights_in_range := 0

func _ready() -> void:
	# Animation par défaut tant que l'ennemi n'est pas activé.
	animated_sprite_2d.play("default")

func go_angry() -> void:
	# Active l'état agressif et sa zone de dégâts.
	animated_sprite_2d.play("pique")
	hb_coll.set_deferred("disabled", false)
	is_angry = true

func go_calm() -> void:
	# Désactive l'état agressif et sa zone de dégâts.
	animated_sprite_2d.play("dépique")
	hb_coll.set_deferred("disabled", true)
	is_angry = false

func _on_lumiere_area_entered(area: Area2D) -> void:
	# On ignore toutes les Area2D qui ne correspondent pas à la lumière du joueur.
	if area.name != "rayon lumiere":
		return

	lights_in_range += 1

	# Une seule lumière suffit à rendre l'ennemi agressif.
	if not is_angry:
		go_angry()

func _on_lumiere_area_exited(area: Area2D) -> void:
	# Même filtrage qu'à l'entrée : seules les zones de lumière nous intéressent.
	if area.name != "rayon lumiere":
		return

	lights_in_range = max(0, lights_in_range - 1)

	# L'ennemi redevient calme uniquement lorsqu'il n'y a
	# plus aucune lumière dans sa zone.
	if lights_in_range == 0 and is_angry:
		go_calm()
