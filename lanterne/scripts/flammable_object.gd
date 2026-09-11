class_name FlammableObject
extends StaticBody2D

@export var size = 1
@onready var sprite: Sprite2D = $sprite
@onready var flamme: Node2D = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $Flamme/anim


func embrase() -> void:
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	# Gestion du visuel
	flamme.visible = true
	sprite.modulate = Color(0.459, 0.193, 0.115, 1.0)
	anim.play("allumage")


func _on_anim_animation_finished() -> void:
	if anim.animation == "allumage": anim.play("feu")
