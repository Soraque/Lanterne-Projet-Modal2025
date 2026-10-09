extends Node2D

@onready var player: CharacterBody2D = $"../PlayerLayer/player"

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

var _base_tints: Array[Color] = []
var _target_tints: Array[Color] = []
var _current_progress: float = 0.0
var _base_light_colors: Array[Color] = []
var target : float = 0.0

func _ready() -> void:
	for cm in canvas_modulates:
		_base_tints.append(cm.color)
		var lum =cm.color.get_luminance()
		_target_tints.append(Color(lum,lum,lum))
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if player:
		var c = Color.from_hsv(0.028, 0.402, 0.8*player.get_coef_usure(), 1.0)
		_base_tints[1]=c
		var lum =c.get_luminance()
		_target_tints[1]= Color(lum,lum,lum)
	var eased = _get_eased(delta)
	if n_b_shader_material:
		n_b_shader_material.set_shader_parameter("desaturation_amount", eased)
	for i in canvas_modulates.size():
		canvas_modulates[i].color = _base_tints[i].lerp(_target_tints[i], eased)


func _on_player_joystick_on():
	print("on")
	if tween_time and tween_time.is_running():
		tween_time.kill()
	
	target = 1.0
	tween_time = create_tween()
	# /time_dilatation compense le ralenti
	tween_time.set_speed_scale(1.0 / max(Engine.time_scale, 0.1))
	tween_time.tween_property(Global, "time_dilatation", time_dilatation_strength, 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

func _get_eased(delta):
	# Lissage exponentiel, stable quel que soit le framerate
	_current_progress = lerp(_current_progress, target, 1.0 - exp(-smoothing_speed * delta))

	return pow(clamp(_current_progress, 0.0, 1.0), curve_power)

func _on_player_joystick_off():
	target = 0.0
	if tween_time and tween_time.is_running():
		tween_time.kill()
		
	tween_time = create_tween()
	tween_time.set_speed_scale(1.0 / max(Engine.time_scale, 0.1))
	tween_time.tween_property(Global, "time_dilatation", 1.0, 0.2)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)
