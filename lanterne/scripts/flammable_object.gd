class_name FlammableObject
extends StaticBody2D

@export var duration := 3.0 #-1 pour infini
@export var bouton := false
@export var destroyable := true
@export var sanslancer := false
@export var spawn := false

@onready var sprite: Sprite2D = $sprite
@onready var flamme: Node2D = $Flamme
@onready var collisionflamme: CollisionShape2D = $Flamme/collisionflamme
@onready var collision: CollisionShape2D = $collision
@onready var anim: AnimatedSprite2D = $Flamme/anim
@onready var light: PointLight2D = $Flamme/light
@onready var animation: AnimationPlayer = $Flamme/AnimationPlayer

var anim_initial_y: float
var combustion_id := 0


func _ready() -> void:
	anim_initial_y = anim.position.y
	
	# Assure que le flux audio est bien préchargé
	var audio = _get_audio_node()
	if audio and audio.stream == null:
		audio.stream = fire_sound_resource
	
	# Si c'est un point de spawn/feu de camp, on vérifie s'il doit être rallumé au chargement
	if spawn:
		var checkpoint_id = get_checkpoint_id()
		if GameManager.is_checkpoint_active(checkpoint_id):
			rallumer_silencieux()


func get_checkpoint_id() -> String:
	var scene_path = get_tree().current_scene.scene_file_path
	return scene_path + "_" + name


func _get_audio_node() -> AudioStreamPlayer2D:
	var audio = get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
	if not audio:
		audio = find_child("AudioStreamPlayer2D", true, false) as AudioStreamPlayer2D
	return audio


func play_fire_sound() -> void:
	var audio = _get_audio_node()
	if audio:
		if audio.stream == null:
			audio.stream = fire_sound_resource
		if not audio.playing:
			audio.play()


func stop_fire_sound() -> void:
	var audio = _get_audio_node()
	if audio and audio.playing:
		audio.stop()


func rallumer_silencieux() -> void:
	# Allume le feu de camp sans déclencher l'animation d'allumage ni superposer le son
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	anim.position.y = anim_initial_y
	anim.visible = true
	flamme.visible = true
	if destroyable:
		sprite.visible = false
	anim.play("feu")
	
	# Ne rejoue le son QUE s'il n'est pas déjà en train de tourner
	play_fire_sound()


func embrase() -> void:
	combustion_id += 1
	var current_id = combustion_id
	
	# Joue l'animation visuelle et sonore d'allumage
	animation.play("allumage")
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	play_fire_sound()
	
	if bouton and has_node("plateforme"):
		$plateforme.activer()
	
	anim.stop()
	anim.position.y = anim_initial_y
	anim.visible = true
	flamme.visible = true
	
	if destroyable:
		sprite.visible = false
		
	anim.play("allumage")
	
	await anim.animation_finished
	if current_id != combustion_id: return
	
	if duration != -1: 
		_sequence_combustion(current_id)
	else: 
		anim.play("feu")
	
	if spawn:
		var gm = GameManager
		var current_scene_path := get_tree().current_scene.scene_file_path
		gm.set_respawn_point(global_position, current_scene_path)
		gm.register_checkpoint(get_checkpoint_id())


func _sequence_combustion(current_id: int) -> void:
	var step_time := duration / 3.0
	
	anim.play("feu")
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	anim.play("feu2")
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	anim.play("feu3")
	anim.position.y = anim_initial_y + (5.0 * anim.scale.y)
	await get_tree().create_timer(step_time).timeout
	if current_id != combustion_id: return
	
	anim.visible = false
	stop_fire_sound()
		
	if bouton and has_node("plateforme"):
		$plateforme.desactiver()
		
	if destroyable:
		queue_free()
	else:
		collision.set_deferred("disabled", false)
		collisionflamme.set_deferred("disabled", true)


func _on_flamme_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and "is_lanterne" in body:
		body.is_lanterne = true
		body.lantern_usure += 0.1
		if spawn:
			body.allumer_lanterne(100)


func _on_zone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_lanterne and not flamme.visible: 
		embrase()
		if spawn:
			body.allumer_lanterne(100)
