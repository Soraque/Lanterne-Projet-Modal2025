class_name FlammableObject
extends StaticBody2D

@export var size = 1
@onready var sprite: Sprite2D = $sprite
@onready var flamme: Flamme = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision



func embrase() -> void:
	#s'appelle peut importe l'objet inflammable et fait apparaitre
	#une flamme récupérable
	collisionflamme.disabled = false
	flamme.visible = true
	sprite.visible = false
	collision.disabled = true
	print("feu")
