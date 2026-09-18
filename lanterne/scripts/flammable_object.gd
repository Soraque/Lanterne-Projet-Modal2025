class_name FlammableObject
extends StaticBody2D

@export var duration := 3.0
@export var destroyable := true
@onready var sprite: Sprite2D = $sprite
@onready var flamme: Node2D = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $Flamme/anim
@onready var light: PointLight2D = $Flamme/light

var anim_initial_y: float


func _ready() -> void:
	anim_initial_y = anim.position.y


func embrase() -> void:
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	if name == "Bouton" and has_node("plateforme"):
		$plateforme.activer()
	
	# Réinitialisation du visuel
	anim.position.y = anim_initial_y
	anim.visible = true
	flamme.visible = true
	
	if destroyable:
		sprite.visible = false
		
	anim.play("allumage")


func _on_anim_animation_finished() -> void:
	if anim.animation == "allumage":
		_sequence_combustion()


func _sequence_combustion() -> void:
	var step_time := duration / 3.0
	
	anim.play("feu")
	await get_tree().create_timer(step_time).timeout
	
	anim.play("feu2")
	await get_tree().create_timer(step_time).timeout
	
	anim.play("feu3")
	anim.position.y += 5.0 * anim.scale.y
	await get_tree().create_timer(step_time).timeout
	
	# Fin de combustion
	anim.visible = false
	if name == "Bouton" and has_node("plateforme"):
		$plateforme.desactiver()
		
	if destroyable:
		queue_free()
	else:
		collision.set_deferred("disabled", false)
		collisionflamme.set_deferred("disabled", true)


func _on_flamme_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and "is_lanterne" in body:
		body.is_lanterne = true
