extends Line2D

@onready var player: CharacterBody2D = $".."
var force_lancer := 600

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func fonction_traj(t : float,v : Vector2)->Vector2:
	var x = (player.velocity.x + v.x) * t
	var y = 1/2*player.get_gravity().y * (t**2) + (player.velocity.y + v.y) * t
	return Vector2(x,y)

func tracer(delta: float,dir_lancer: Vector2)->void:
	clear_points()
	var pos = Vector2.ZERO
	var vit = force_lancer*dir_lancer
	for i in range(10):
		vit += player.get_gravity() * delta
		pos += vit
		print(pos)
		add_point(pos)
	
