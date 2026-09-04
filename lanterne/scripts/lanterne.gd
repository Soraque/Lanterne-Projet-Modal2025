extends RigidBody2D


@onready var player_light: PointLight2D = $player_light
@onready var point_light_2d: PointLight2D = $player_light
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

var isLit := true
var is_destroying := false

func destroy(body: Node2D) -> void:
	if body is FlammableObject:
		body.embrase()
	
	player_light.enabled = false
	$Sprite2D.hide()
	if is_destroying: return
	is_destroying = true

	cpu_particles_2d.emitting = true
	# Attendre la fin des particules avant de faire disparaitre
	await get_tree().create_timer(cpu_particles_2d.lifetime).timeout
	queue_free()




func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		return
	if not is_destroying: destroy(body)
