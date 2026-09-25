extends Camera2D

@export var bounds_rect: ReferenceRect
@export var shake_fade: float = 10.0

var _shake_strength: float = 0.0

func _ready() -> void:
	var rect = bounds_rect.get_global_rect()
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.position.x + rect.size.x)
	limit_bottom = int(rect.position.y + rect.size.y)

func trigger_shake(shake) -> void:
	_shake_strength = shake

func _process(delta: float) -> void:
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)
		offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
