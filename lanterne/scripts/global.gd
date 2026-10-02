extends Node2D

## ___Ralenti du temps___
# Forcer le type float (1.0 au lieu de 1)
@export var time_dilatation: float = 1.0:
	set(value):
		time_dilatation = value
		Engine.time_scale = value
const time_dilatation_strength: float = 0.1
var tween_time: Tween

## ___Shader___
@export var n_b_shader_material: ShaderMaterial
@export var canvas_modulates: Array[CanvasModulate] = []  # Background + Foreground ici
@export var smoothing_speed: float = 6.0                   # + haut = rattrape la cible + vite
@export var curve_power: float = 0.7                       # < 1 = pousse plus vite vers 1 ; 1.0 = pas de courbe
@export var lights: Array[Light2D] = []  # tous tes PointLight2D / DirectionalLight2D


var _base_tints: Array[Color] = []
var _current_progress: float = 0.0
var _base_light_colors: Array[Color] = []

func _ready() -> void:
	for cm in canvas_modulates:
		_base_tints.append(cm.color)
	for l in lights:
		_base_light_colors.append(l.color)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var target := 1.0 - Global.time_dilatation
	# Lissage exponentiel, stable quel que soit le framerate
	_current_progress = lerp(_current_progress, target, 1.0 - exp(-smoothing_speed * delta))

	var eased := pow(clamp(_current_progress, 0.0, 1.0), curve_power)

	if n_b_shader_material:
		n_b_shader_material.set_shader_parameter("desaturation_amount", eased)

	for i in canvas_modulates.size():
		canvas_modulates[i].color = _base_tints[i].lerp(Color.DARK_GRAY, eased)

	for i in lights.size():
		lights[i].color = _base_light_colors[i].lerp(Color.DARK_GRAY, eased)

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
