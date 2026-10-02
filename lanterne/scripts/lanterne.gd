extends RigidBody2D

@onready var player_light: PointLight2D = $player_light
@onready var point_light_2d: PointLight2D = $player_light
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var collision_shape_2d2: CollisionShape2D = $Sprite2D/Area2D_grande/CollisionShape2D
@onready var area_2d: Area2D = $Area2D

var isLit := true
var is_destroying := false
var bien_lance = false # true lorsque la lanterne est sortie de l'hitbox du joueur


func lancer(direction: Vector2, vitesse: Vector2, force_lancer = 1000, impact_vitesse_initiale = 0.2):
	linear_velocity = direction * force_lancer + vitesse * impact_vitesse_initiale
	bien_lance = false


func destroy(body: Node2D) -> void:
	if is_destroying: return
	is_destroying = true

	# 1. Empêcher toute nouvelle détection immédiatement
	area_2d.set_deferred("monitoring", false)
	collision_shape_2d.set_deferred("disabled", true)
	collision_shape_2d2.set_deferred("disabled", true)
	
	# 2. Stoper immédiatement le mouvement physique de la lanterne
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	set_deferred("freeze", true)# Gèle la physique du RigidBody2D

	if body is FlammableObject:
		body.embrase()
	
	player_light.enabled = false
	$Sprite2D.hide()

	cpu_particles_2d.emitting = true
	# Attendre la fin des particules avant de faire disparaître
	await get_tree().create_timer(cpu_particles_2d.lifetime).timeout
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_destroying:
		return
		
	if body is CharacterBody2D:
		if bien_lance:
			body.is_lanterne = true
			destroy(body)
		return
		
	destroy(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and not bien_lance:
		bien_lance = true
