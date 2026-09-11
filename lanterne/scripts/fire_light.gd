extends PointLight2D


@export var base_energy: float = 1.0
@export var flicker_intensity: float = 0.2
@export var speed: float = 20

var noise := FastNoiseLite.new()
var time_passed: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.1

func _process(delta: float) -> void:
	time_passed += delta * speed
	var sample := noise.get_noise_1d(time_passed)
	energy = base_energy + (sample * flicker_intensity)
