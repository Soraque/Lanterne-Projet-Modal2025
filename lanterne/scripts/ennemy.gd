extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hb_coll: CollisionShape2D = $Killzone/CollisionShape2D

var is_angry = false
# Compteur de lumières actuellement dans la zone
var lights_in_range := 0


func _ready() -> void:
	animated_sprite_2d.play("default")


func go_angry() -> void:
	animated_sprite_2d.play("pique")
	hb_coll.set_deferred("disabled", false)
	is_angry = true


func go_calm() -> void:
	animated_sprite_2d.play("dépique")
	hb_coll.set_deferred("disabled", true)
	is_angry = false


func _on_lumiere_area_entered(area: Area2D) -> void:
	if area.name != "rayon lumiere":
		return
	lights_in_range += 1
	if not is_angry:
		go_angry()


func _on_lumiere_area_exited(area: Area2D) -> void:
	if area.name != "rayon lumiere":
		return
	
	# Une lumiere sort
	lights_in_range = max(0, lights_in_range - 1)
	if lights_in_range == 0 and is_angry:
		go_calm()
