extends Node2D

@export var isLit = true
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var smoke_particles: CPUParticles2D = $CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if isLit:
		animated_sprite.play("Fire")
		smoke_particles.show()
	else:
		animated_sprite.play("No fire")
		smoke_particles.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
