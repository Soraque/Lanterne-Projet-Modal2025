extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#animation de scintillement
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.2, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
