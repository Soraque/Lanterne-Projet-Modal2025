extends StaticBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var active: Sprite2D = $activé


func activer() -> void:
	collision_shape_2d.set_deferred("disabled", false)
	sprite_2d.visible = false
	active.visible = true


func desactiver() -> void:
	collision_shape_2d.set_deferred("disabled", true)
	sprite_2d.visible = true
	active.visible = false
