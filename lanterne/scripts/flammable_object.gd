class_name FlammableObject
extends StaticBody2D

@export var duration = 3
@onready var sprite: Sprite2D = $sprite
@onready var flamme: Node2D = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $Flamme/anim
@onready var light: PointLight2D = $Flamme/light


func embrase() -> void:
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	# Gestion du visuel
	flamme.visible = true
	sprite.visible = false
	anim.play("allumage")



func _on_anim_animation_finished() -> void:
	if anim.animation == "allumage":
		_sequence_combustion()


func _sequence_combustion() -> void:
	# 1. Première étape : "feu"
	anim.play("feu")
	await get_tree().create_timer(duration/3).timeout
	
	# 2. Deuxième étape : "feu2"
	anim.play("feu2")
	await get_tree().create_timer(duration/3).timeout
	
	# 3. Troisième étape : "feu3"
	anim.play("feu3")
	anim.position.y += 5*anim.scale.y
	await get_tree().create_timer(duration/3).timeout
	
	# 4. Destruction du nœud
	queue_free()


func _on_flamme_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if "is_lanterne" in body:
			body.is_lanterne = true
