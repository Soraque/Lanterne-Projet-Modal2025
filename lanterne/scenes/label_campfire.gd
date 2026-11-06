extends Label
var number
var total = "16"
var text_label = "1/"+total
const pos_init = Vector2(-20,-16)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	number = get_parent().name.trim_prefix("C")
	text_label = number + "/" + total 
	text = text_label
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_campfire_campfire_lit() -> void:
# Animation du texte
	visible = true
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	pivot_offset = size / 2.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", pos_init.y - 25.0, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE)
