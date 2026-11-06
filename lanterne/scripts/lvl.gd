extends Node2D
@onready var player: CharacterBody2D = $PlayerLayer/player
@onready var canvas_modulate_back: CanvasModulate = $World/background/BackgroundContent/CanvasModulate
@onready var zone_dezoom_cam: Area2D = $World/zone_dezoom_cam

var zoom_cible := Vector2(1, 1)
var vitesse_zoom := 1.5

func _physics_process(delta: float) -> void:
	# -- 1. Actualisation luminosité background --
	if not GameManager.soleilallume:
		canvas_modulate_back.set_color(Color.from_hsv(0.028, 0.402, 0.8 * player.get_coef_usure(), 1.0))


func _on_zone_dezoom_cam_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var camera = body.get_node_or_null("Camera2D") as Camera2D
		if camera:
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(camera, "zoom", zoom_cible, vitesse_zoom)


func _on_zone_dezoom_cam_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		var camera = body.get_node_or_null("Camera2D") as Camera2D
		if camera:
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(camera, "zoom", Vector2(1.8, 1.8), vitesse_zoom)
