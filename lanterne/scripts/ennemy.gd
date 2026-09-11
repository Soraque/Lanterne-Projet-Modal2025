extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hb_coll: CollisionShape2D = $hitbox/CollisionShape2D

var is_angry = false

func go_angry() -> void:
	animated_sprite_2d.play("pique")
	hb_coll.disabled = false
	is_angry = true

func go_calm() -> void:
	animated_sprite_2d.play("dépique")
	hb_coll.disabled = true
	is_angry = false

func _on_lumiere_area_entered(area: Area2D) -> void:
	if area.name != "rayon lumiere": return
	#si ily a une lumiere trop proche on active lennemi
	go_angry()

func _on_lumiere_area_exited(area: Area2D) -> void:
	if area.name != "rayon lumiere": return
	#inversement
	go_calm()
