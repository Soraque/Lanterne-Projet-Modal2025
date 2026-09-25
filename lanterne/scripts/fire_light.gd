extends PointLight2D


@export var base_energy: float = 1
@export var flicker_intensity: float = 0.2
@export var speed: float = 20
@onready var rayon_coll: CollisionShape2D = $"rayon lumiere/CollisionShape2D"

var noise := FastNoiseLite.new()
var time_passed: float = 0.0


func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.1
	visibility_changed.connect(_on_visibility_changed)
	_update_collision_state()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	time_passed += delta * 5.0
	var sample := noise.get_noise_1d(time_passed)
	energy = base_energy + (sample * 0.5)


func _on_visibility_changed() -> void:
	_update_collision_state()


func _update_collision_state() -> void:
	rayon_coll.set_deferred("disabled", not is_visible_in_tree())
