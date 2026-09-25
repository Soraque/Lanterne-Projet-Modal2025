extends Camera2D

@export var bounds_rect: ReferenceRect
@export var shake_fade: float = 10.0

var _shake_strength: float = 0.0


func _ready() -> void:
	# Si aucun ReferenceRect n'est assigné à la main, on cherche celui du niveau actuel
	if not bounds_rect:
		bounds_rect = get_tree().current_scene.get_node_or_null("ReferenceRect") as ReferenceRect
	
	_update_limits()


func _update_limits() -> void:
	if bounds_rect:
		var rect = bounds_rect.get_global_rect()
		limit_left = int(rect.position.x)
		limit_top = int(rect.position.y)
		limit_right = int(rect.position.x + rect.size.x)
		limit_bottom = int(rect.position.y + rect.size.y)


func trigger_shake(shake: float) -> void:
	_shake_strength = shake


func _process(delta: float) -> void:
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
