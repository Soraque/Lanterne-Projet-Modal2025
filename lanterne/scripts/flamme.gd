class_name Flamme
extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	
