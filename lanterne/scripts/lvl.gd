extends Node2D
@onready var player: CharacterBody2D = $PlayerLayer/player
@onready var canvas_modulate_back: CanvasModulate = $WorldViewportContainer/WorldViewport/background/CanvasModulate


func _physics_process(delta: float) -> void:
	# -- 1. Actualisation luminosité background --
	canvas_modulate_back.set_color(Color.from_hsv(0.028, 0.402, 0.8*player.get_coef_usure(), 1.0))
	
