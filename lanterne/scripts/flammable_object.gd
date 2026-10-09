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
	
	# Si c'est un point de spawn/feu de camp, on vérifie s'il doit être rallumé au chargement
	if spawn:
		var checkpoint_id = get_checkpoint_id()
		if GameManager.is_checkpoint_active(checkpoint_id):
			rallumer_silencieux()


func get_checkpoint_id() -> String:
	var scene_path = get_tree().current_scene.scene_file_path
	return scene_path + "_" + name


# Joue le son de boucle (ex: AudioStreamPlayer2D) s'il n'est pas déjà en train de tourner
func play_fire_sound() -> void:
	var audio = get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
	if audio and not audio.playing:
		audio.play()


# Joue les sons secondaires d'allumage/one-shot avec montée de fréquence en combo
func play_ignition_sounds() -> void:
	var audio2 = get_node_or_null("AudioStreamPlayer2D2") as AudioStreamPlayer2D
	var audio3 = get_node_or_null("AudioStreamPlayer2D3") as AudioStreamPlayer2D
	
	if audio2:
		var new_pitch = GameManager.register_ignition_combo()
		audio2.pitch_scale = new_pitch
		if not audio2.playing:
			audio2.play()

	if audio3 and not audio3.playing:
		audio3.play()


# Arrête tous les sons de feu associés lorsque la combustion se termine
func stop_fire_sound() -> void:
	for node_name in ["AudioStreamPlayer2D", "AudioStreamPlayer2D2", "AudioStreamPlayer2D3"]:
		var audio = get_node_or_null(node_name) as AudioStreamPlayer2D
		if audio and audio.playing:
			audio.stop()


func rallumer_silencieux() -> void:
	_set_burning(true)
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	anim.position.y = anim_initial_y
	anim.visible = true
	flamme.visible = true
	if destroyable:
		sprite.visible = false
	anim.play("feu")
	
	# Au chargement de scène, on ne relance QUE le son de boucle continu s'il est arrêté
	play_fire_sound()


func embrase() -> void:
	combustion_id += 1
	var current_id = combustion_id
	_set_burning(true)
	animation.play("allumage")
	collision.set_deferred("disabled", true)
	collisionflamme.set_deferred("disabled", false)
	
	# Déclenche l'allumage initial : son unique d'allumage + son de boucle
	play_ignition_sounds()
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
	
	_set_burning(false)
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

func _set_burning(value: bool) -> void:
	if value:
		add_to_group("feu_allume")
	else:
		remove_from_group("feu_allume")
