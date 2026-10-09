extends Camera2D

@export var bounds_rect: ReferenceRect
@export var shake_fade: float = 10.0
@export var player: Node2D
@export var target_offset_y: float = -40.0 
@export var target_offset_x: float = 40

var input_lancer
var aim_offset = Vector2.ZERO
var _shake_strength: float = 0.0
var aim_offset_strengh = 0
const max_aim_offset_strength = 40
var aim_tween : Tween
func _ready() -> void:
	# Récupère le joueur via le groupe s'il n'est pas assigné dans l'Inspecteur
	if not player:
		player = get_tree().get_first_node_in_group("player") as Node2D

	# Récupère le ReferenceRect du niveau s'il n'est pas assigné
	if not bounds_rect:
		bounds_rect = get_tree().current_scene.get_node_or_null("ReferenceRect") as ReferenceRect
	
	_update_limits()


func _update_limits() -> void:
	if bounds_rect:
		var rect = bounds_rect.get_global_rect()
		limit_left = int(rect.position.x - target_offset_x)
		# On compense la limite haute avec target_offset_y pour ne pas voir au-dessus du cadre
		limit_top = int(rect.position.y - target_offset_y)
		limit_right = int(rect.position.x + rect.size.x)
		limit_bottom = int(rect.position.y + rect.size.y)


func trigger_shake(shake: float) -> void:
	_shake_strength = shake


func _process(delta: float) -> void:
	if player:
		global_position = player.global_position
	
	# Gestion combinée du Shake et du décalage vertical
	var shake_offset := Vector2.ZERO
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		shake_offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	aim_offset = aim_offset_strengh*Input.get_vector("lancer left", "lancer right", "lancer up", "lancer down")
	offset = Vector2(target_offset_x, target_offset_y) + shake_offset + aim_offset
	

func _on_player_joystick_off() -> void:
	if aim_tween and aim_tween.is_running() :
		aim_tween.kill()
	aim_tween = create_tween()
	aim_tween.tween_property(self, "aim_offset_strengh", 0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _on_player_joystick_on() -> void:
	if aim_tween and aim_tween.is_running() :
		aim_tween.kill()
	aim_tween = create_tween()
	aim_tween.tween_property(self, "aim_offset_strengh", max_aim_offset_strength, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
