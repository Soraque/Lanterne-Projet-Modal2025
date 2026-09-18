class_name Killzone
extends Area2D



func _on_body_entered(body: Node2D) -> void:
	print("a")
	if body is CharacterBody2D:
		print("b")
