extends Node

# Forcer le type float (1.0 au lieu de 1)
@export var time_dilatation: float = 1.0:
	set(value):
		time_dilatation = value
		print(value)
		
const time_dilatation_strength: float = 0.3
var tween_time: Tween

func _ready() -> void:
	# Garantit que ce nœud continue de tourner à vitesse normale
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_player_joystick_on():
	if tween_time and tween_time.is_running():
		tween_time.kill()
		
	tween_time = create_tween()
	# /time_dilatation compense le ralenti
	tween_time.set_speed_scale(1.0 / max(Engine.time_scale, 0.1))
	tween_time.tween_property(Global, "time_dilatation", time_dilatation_strength, 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

func _on_player_joystick_off():
	if tween_time and tween_time.is_running():
		tween_time.kill()
		
	tween_time = create_tween()
	tween_time.set_speed_scale(1.0 / max(Engine.time_scale, 0.1))
	tween_time.tween_property(Global, "time_dilatation", 1.0, 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
