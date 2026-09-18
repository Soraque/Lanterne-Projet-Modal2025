class_name FlammableObject
extends StaticBody2D

@export var duration := 3.0 #-1 pour infini
@export var destroyable := true
@export var sanslancer := false
@onready var sprite: Sprite2D = $sprite
@onready var flamme: Node2D = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $Flamme/anim
@onready var light: PointLight2D = $Flamme/light

var anim_initial_y: float
var combustion_id := 0


func _ready() -> void:
	anim_initial_y = anim.position.y


func embrase() -> void:
	# Chaque appel génère un nouvel ID unique qui annule tout 'await' en cours
	combustion_id += 1
	var current_id = combustion_id
	
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	if name == "Bouton" and has_node("plateforme"):
		$plateforme.activer()
	
	# Réinitialisation forcée du visuel
	anim.stop() # Arrête l'animation en cours
	anim.position.y = anim_initial_y
	anim.visible = true
	flamme.visible = true
	
	if destroyable:
		sprite.visible = false
		
	# Jouer l'animation depuis la frame 0
	anim.play("allumage")
	
	# On attend la fin de l'allumage manuellement pour ne pas dépendre du signal
	await anim.animation_finished
	if current_id != combustion_id: return # Si rallumé entre temps, on abandonne ce thread
	
	if duration != -1: _sequence_combustion(current_id)
	else: 
		anim.play("feu")


func _sequence_combustion(current_id: int) -> void:
	var step_time := duration / 3.0
	
	anim.play("feu")
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	anim.play("feu2")
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	anim.play("feu3")
	anim.position.y = anim_initial_y + (5.0 * anim.scale.y)
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	# Extinction (uniquement si le timer n'a pas été interrompu par un nouveau lancer)
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

func _on_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_lanterne : embrase()
