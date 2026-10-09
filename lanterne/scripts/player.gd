extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var lumiere: PointLight2D = $Fire_light
@onready var aim_line: Line2D = $Aim_line
@onready var pointeur: Polygon2D = $Pointeur
@export var lanterne_scene: PackedScene
@onready var runparticles: CPUParticles2D = $runparticles
@onready var wallparticles: CPUParticles2D = $wallparticles
@onready var course_audio: AudioStreamPlayer2D = $course
@onready var filtre_mort: ColorRect = $"../../UpperLayer/Fond_Mort"


# --- Nœuds audio pour le saut et l'atterrissage ---
@onready var jump_audio: AudioStreamPlayer = $jump
@onready var land_audio: AudioStreamPlayer = $land

# --- Mouvement général ---
const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const ACCELERATION = 4000.0
const FRICTION = 13000.0
const AIR_CONTROL = 7000.0

# --- Wall Jump ---
const WALL_JUMP_HORIZONTAL_SPEED = 500.0
const WALL_JUMP_VERTICAL_SPEED = -350.0
const WALL_JUMP_LOCK_TIME = 0.18

var wall_jump_lock_timer := 0.0
var wall_jump_direction := 0

# --- Dash ---
const DASH_SPEED = 900.0
const DASH_DURATION = 0.09
const DASH_COOLDOWN = 0.35

var can_dash = true
var dash_timer := 0.0
var vitesse_debut = 0
var looking_direction = 0

# --- Saut ---
var jump_buffer = false
var jump_available = false
var jbuffertime = 0.1

# --- Lanterne ---
@export var is_lanterne = true
var lantern_ready = false
@export var lantern_usure = 100 # Valeur d'usure de la lanterne de 0 : éteint à 100 : complètement allumé
var direction_lancer = Vector2.ZERO
var anim_str = ""
var force_lancer = 1000
var impact_vitesse_initiale = 0.2

# --- Dégâts / Invincibilité ---
var isInvincible = false
var invincible_time = 1.0

# --- Mort lente (extinction) ---
@export var mort_duree := 5.0
@export var mort_recuperation := 1.0
var mort_progress := 0.0                # 0.0 = vivant, 1.0 = mort
var is_dying := false                   # true tant que le joueur est en danger
var is_dead := false                    # true dès que die() est lancée

# --- Boost lors des collisions ---
var was_on_floor = false
var was_on_wall = false
var collision_boost_cooldown = 0.1
const max_boost_speed = 380
var previous_velocity = Vector2(0, 0)

# Time dilatation
signal joystick_on
signal joystick_off


func _ready() -> void:
	# On s'assure que les nœuds sont visibles, l'émission se gère via .emitting
	runparticles.show()
	runparticles.emitting = false
	
	wallparticles.show()
	wallparticles.emitting = false

	var mat = animated_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_modifier", 0.0)
		
	if GameManager.Changinglvl:
		# Réinitialise les états de mouvement parasites de l'ancienne scène
		dash_timer = 0.0
		wall_jump_lock_timer = 0.0
		vitesse_debut = 0
		
		# Applique la position et la vitesse
		global_position = GameManager.changepos
		velocity = GameManager.vitJ
		previous_velocity = GameManager.vitJ
		
		# Restaure l'état et l'usure de la lanterne
		lantern_usure = GameManager.lantern_usure_saved
		is_lanterne = GameManager.is_lanterne_saved
		
		GameManager.Changinglvl = false
	elif GameManager.has_respawn_point and GameManager.respawn_scene == get_tree().current_scene.scene_file_path:
		# Repositionne le joueur au feu de camp lors d'un respawn après mort
		global_position = GameManager.respawn_position
		lantern_usure = 100.0
		is_lanterne = true

func die() -> void:
	if is_dead:
		return
	is_dead = true
	var gm = GameManager
	gm.vitJ = Vector2.ZERO
	# Réinitialise la sauvegarde de usure au respawn
	gm.lantern_usure_saved = 100.0
	gm.is_lanterne_saved = true
	gm.reset_combo()
	
	if gm.has_respawn_point and gm.respawn_scene != get_tree().current_scene.scene_file_path:
		get_tree().change_scene_to_file.call_deferred(gm.respawn_scene)
	else:
		get_tree().reload_current_scene.call_deferred()
	is_lanterne = true


func jump() -> void:
	if jump_available:
		velocity.y = JUMP_VELOCITY
		jump_available = false
		jump_buffer = false
		if jump_audio:
			jump_audio.play()
	else:
		jump_buffer = true
		get_tree().create_timer(jbuffertime).timeout.connect(on_jump_buffer_timeout)


func _physics_process(delta: float) -> void:
	var direction_h := Input.get_axis("left", "right")
	var input_lancer := Input.get_vector("lancer left", "lancer right", "lancer up", "lancer down")

	# --- 1. Dash en cours ---
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = vitesse_debut + looking_direction * DASH_SPEED
		velocity.y = 0
		
		if animated_sprite.animation != "dash" + anim_str:
			animated_sprite.play("dash" + anim_str)
		
		if dash_timer <= 0.0:
			velocity.x = vitesse_debut
			
		course_audio.stop()
		move_and_slide()
		
		# Mise à jour des états au sol / mur pour le dash
		was_on_floor = is_on_floor()
		was_on_wall = is_on_wall()
		previous_velocity = velocity
		return

	# --- 2. Gravité & Sol ---
	if not is_on_floor():
		jump_available = false
		velocity += get_gravity() * delta
	else:
		can_dash = true
		jump_available = true
		if jump_buffer:
			jump()

	# --- Wall Jump Timer ---
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	# --- 3. Déclenchement du Dash ---
	if Input.is_action_just_pressed("dash") and dash_cd_timer.is_stopped() and can_dash:
		runparticles.emitting = false
		wallparticles.emitting = false
		course_audio.stop()
		can_dash = false
		dash_timer = DASH_DURATION
		velocity.y = 0
		wall_jump_lock_timer = 0
		
		if is_on_wall() and not is_on_floor():
			vitesse_debut = 0
			looking_direction = get_wall_normal().x / abs(get_wall_normal().x)
		else:
			looking_direction = -int(animated_sprite.flip_h) * 2 + 1
			if velocity.x * looking_direction > 0:
				vitesse_debut = velocity.x
			else:
				vitesse_debut = 0
		
		animated_sprite.play("dash" + anim_str)
		dash_cd_timer.start(DASH_COOLDOWN)

	# --- 4. Lancer de la lanterne ---
	if is_lanterne:
		if input_lancer.length() > 0.4:
			direction_lancer = input_lancer.normalized()
			aim_line.tracer(delta / Engine.time_scale, direction_lancer, force_lancer, impact_vitesse_initiale)
			if not lantern_ready:
				joystick_on.emit()
			lantern_ready = true
		elif lantern_ready:
			joystick_off.emit()
			aim_line.clear_points()
			pointeur.visible = false
			
			lancer_lanterne()
			is_lanterne = false
			lantern_ready = false
			direction_lancer = Vector2.ZERO
	
	Engine.time_scale = Global.time_dilatation

	# --- 5. État lanterne ---
	if is_lanterne:
		anim_str = ""
		lumiere.visible = true
	else:
		anim_str = "_sans_lanterne"
		lumiere.visible = false

	# --- 6. Saut & Wall Jump ---
	if Input.is_action_just_pressed("jump"):
		runparticles.emitting = false
		wallparticles.emitting = false
		course_audio.stop()
		jump()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.3

	if Input.is_action_just_pressed("jump") and is_on_wall() and not is_on_floor():
		runparticles.emitting = false
		wallparticles.emitting = false
		course_audio.stop()
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
		velocity.y = WALL_JUMP_VERTICAL_SPEED
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
		jump_buffer = false
		jump_available = false
		if jump_audio:
			pass
			#jump_audio.play()

	# --- 7. Déplacement horizontal ---
	if wall_jump_lock_timer > 0.0:
		pass
	elif direction_h != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, direction_h * SPEED, accel * delta)
	else:
		var friction = FRICTION if is_on_floor() else AIR_CONTROL * 0.5
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# --- 8. Orientation Sprite ---
	if direction_h > 0:
		animated_sprite.flip_h = false
	elif direction_h < 0:
		animated_sprite.flip_h = true

	# --- 9. Animations, Particules & Sons ---
	runparticles.direction.x = 1.0 if animated_sprite.flip_h else -1.0

	if is_on_floor() and dash_timer <= 0.0:
		wallparticles.emitting = false
		if direction_h == 0:
			animated_sprite.play("idle" + anim_str)
			runparticles.emitting = false
			course_audio.stop()
		elif abs(direction_h) < 0.4:
			animated_sprite.play("marche" + anim_str, 1.0 * abs(direction_h) / 0.4)
			runparticles.emitting = false
			course_audio.stop()
		else:
			animated_sprite.play("run" + anim_str, 1.0 * abs(direction_h))
			runparticles.emitting = true
			if not course_audio.playing:
				course_audio.play()
	else:
		runparticles.emitting = false
		course_audio.stop()
		if is_on_wall():
			wallparticles.emitting = true
			
			wallparticles.position.x = -get_wall_normal().x * 8
			
			if velocity.y <= 0:
				animated_sprite.play("wall_slide_jump" + anim_str)
				wallparticles.direction.y = 1.0
			else:
				if animated_sprite.animation != "wall_slide_fall" + anim_str and animated_sprite.animation != "wall_slide_grosse_chute":
					animated_sprite.play("wall_slide_fall" + anim_str)
				wallparticles.direction.y = -1.0
		else:
			wallparticles.emitting = false
			if velocity.y <= 0:
				animated_sprite.play("jump" + anim_str)
			else:
				if animated_sprite.animation != "fall" + anim_str and animated_sprite.animation != "chute longue":
					animated_sprite.play("fall" + anim_str)
	
	# --- 10. Déplacement de la physique ---
	move_and_slide()

	# --- 11. Détection de l'atterrissage (Placée APRES move_and_slide) ---
	if is_on_floor() and not was_on_floor:
		if land_audio:
			land_audio.play()
		print("ouais")
	
	# --- 12. Actualisation usure lanterne ---
	if lantern_usure > 0.0:
		lantern_usure = maxf(lantern_usure - delta * 5.0, 0.0)

	# --- 12 bis. Mort lente ---
	_update_mort_lente(delta)
	
	# --- 13. Lumière lanterne ---
	var coef = get_coef_usure()
	if coef > 0.1:
		lumiere.set_texture_scale(1.5 + 6.5 * (coef - 0.1))
	else:
		lumiere.base_energy = coef * 10


	if collision_boost_cooldown > 0:
		collision_boost_cooldown -= delta

	# --- 14. Collision Wall Boost ---
	var collision_count = get_slide_collision_count()
	if collision_count > 0:
		for i in range(collision_count):
			if (is_on_wall() and not was_on_wall) and collision_boost_cooldown <= 0.0:
				if -previous_velocity.y < max_boost_speed and previous_velocity.y < 0:
					velocity.y = -max_boost_speed
					collision_boost_cooldown = 0.1

	was_on_floor = is_on_floor()
	was_on_wall = is_on_wall()
	previous_velocity = velocity


func lancer_lanterne() -> void:
	var lanterne = lanterne_scene.instantiate()
	lanterne.global_position = global_position
	get_parent().add_child(lanterne)
	lanterne.lancer(direction_lancer, velocity, force_lancer, impact_vitesse_initiale)


func on_jump_buffer_timeout() -> void:
	jump_buffer = false


func _start_extinction() -> void:
	is_dying = true
	var tween := create_tween()
	tween.tween_property(filtre_mort, "color:a", 1.0, 5.0)
	await tween.finished
	await die()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "fall" + anim_str:
		animated_sprite.play("chute longue" + anim_str)

	if animated_sprite.animation == "wall_slide_fall" + anim_str:
		animated_sprite.play("wall_slide_grosse_chute" + anim_str)


func get_coef_usure() -> float:
	var x = lantern_usure / 100.0
	return (400 * x**3 - 600 * x**2 + 319 * x) / 119.0

func _update_mort_lente(delta: float) -> void:
	if is_dead:
		return

	is_dying = _est_en_danger()

	if is_dying:
		mort_progress += delta / mort_duree
	else:
		mort_progress -= delta / mort_recuperation
	mort_progress = clampf(mort_progress, 0.0, 1.0)

	filtre_mort.color.a = mort_progress

	if mort_progress >= 1.0:
		die()


func _est_en_danger() -> bool:
	# Avec la lanterne : seule l'usure compte.
	if is_lanterne:
		return lantern_usure <= 0.0
	# Sans lanterne (lancée) : danger s'il n'y a aucun feu hors feux de camp.
	return not _feu_actif_present()


func _feu_actif_present() -> bool:
	for feu in get_tree().get_nodes_in_group("feu_allume"):
		if feu is FlammableObject and not feu.spawn:
			return true
	return false

func allumer_lanterne(value: float) -> void:
	var tween = create_tween()
	tween.tween_property(self, "lantern_usure", value, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
