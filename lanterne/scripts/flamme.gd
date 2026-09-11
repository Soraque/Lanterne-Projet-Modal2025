class_name Flamme
extends Area2D


@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $anim


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	
