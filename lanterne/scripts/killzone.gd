class_name Killzone
extends Area2D

func _ready() -> void:
	# Se connecte automatiquement au démarrage si ce n'est pas déjà fait
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: 
		get_tree().reload_current_scene.call_deferred()
