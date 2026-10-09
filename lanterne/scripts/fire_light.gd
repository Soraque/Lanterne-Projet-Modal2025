extends PointLight2D


@export var base_energy: float = 1
@export var flicker_intensity: float = 0.2
@export var speed: float = 20
@onready var rayon_coll: CollisionShape2D = $"rayon lumiere/CollisionShape2D"
@export var smoothing_speed: float = 15                  # + haut = rattrape la cible + vite
@export var curve_power: float = 0.7 

var _current_progress: float = 0.0
var noise := FastNoiseLite.new()
var time_passed: float = 0.0
var base_light_color: Color

func _ready() -> void:
	base_light_color=self.color
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
	color = base_light_color.lerp(Color.DARK_GRAY, _get_eased(delta))
	

func _get_eased(delta):
	var target = 1.0 - Global.time_dilatation
	# Lissage exponentiel, stable quel que soit le framerate
	_current_progress = lerp(_current_progress, target, 1.0 - exp(-smoothing_speed * delta))

	return pow(clamp(_current_progress, 0.0, 1.0), curve_power)

func _on_visibility_changed() -> void:
	_update_collision_state()


func _update_collision_state() -> void:
	rayon_coll.set_deferred("disabled", not is_visible_in_tree())
