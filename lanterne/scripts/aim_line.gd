extends Line2D
@onready var rayon: RayCast2D = $"../RayCast2D"
@onready var player: CharacterBody2D = $".."
@onready var pointeur: Polygon2D = $"../Pointeur"
var force_lancer := 600

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rayon.add_exception($"../CollisionShape2D")

func tracer(delta: float,dir_lancer: Vector2)->void:
	clear_points()
	var pos = Vector2.ZERO
	var vit = force_lancer*dir_lancer + player.velocity
	for i in range(100):
		var last_pos = pos
		vit += player.get_gravity() * delta
		pos += vit * delta
		add_point(pos)
		rayon.position = last_pos
		rayon.target_position = pos-last_pos
		rayon.force_raycast_update()
		if rayon.is_colliding():
			pos = rayon.get_collision_point()-player.position
			pointeur.visible = true
			add_point(pos)
			pointeur.position = pos
			break
		elif i==99:
			pointeur.visible = false
		add_point(pos)
	
