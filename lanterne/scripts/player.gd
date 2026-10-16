extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var lumiere: PointLight2D = $Fire_light
@onready var aim_line: Line2D = $Aim_line
@onready var pointeur: Polygon2D = $Pointeur
@export var lanterne_scene: PackedScene
@onready var runparticles: CPUParticles2D = $runparticles
@onready var wallparticles: CPUParticles2D = $wallparticles
@onready var filtre_mort: ColorRect = $"../../UpperLayer/Fond_Mort"

# --- Sons ---
@onready var jump_audio: AudioStreamPlayer = $sons/saut
@onready var course_audio: AudioStreamPlayer2D = $sons/course
@onready var land_audio: AudioStreamPlayer = $sons/land
@onready var slowdown_audio: AudioStreamPlayer = $sons/slowdown
@onready var dash_audio: AudioStreamPlayer = $sons/dash
@onready var break_audio: AudioStreamPlayer = $sons/break
@onready var music_audio: AudioStreamPlayer = $sons/music

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

# --- Saut & marges de tolérance ---
const COYOTE_TIME = 0.02       # saut possible juste après avoir quitté le sol
const JUMP_BUFFER_TIME = 0.15    
const WALL_COYOTE_TIME = 0.10     # wall jump possible juste après avoir quitté le mur
const WALL_CHECK_DISTANCE = 5.0  

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var wall_coyote_timer := 0.0
var wall_normal_x := 0.0          # normale x du dernier mur vu (donne le sens du rebond)
var _wall_col := KinematicCollision2D.new()

# --- Lanterne ---
const LANCER_DURATION = 2.0

@export var is_lanterne := true
@onready var lightparticle: CPUParticles2D = $lightparticle
var lantern_ready = false
@export var lantern_usure := 100.0 # Valeur d'usure de la lanterne de 0 : éteint à 100 : complètement allumé
var direction_lancer = Vector2.ZERO
var force_lancer_lanterne = false
var lancer_timer := 0.0
var anim_str = ""
var force_lancer = 1000
var impact_vitesse_initiale = 0.2
var lantern_duration = 10 #secondes
var initial_light_particle_amount := 50


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

	if lightparticle:
		initial_light_particle_amount = lightparticle.amount

	var mat = animated_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_modifier", 0.0)
		
	if GameManager.Changinglvl:
		# Réinitialise les états de mouvement parasites de l'ancienne scène
		dash_timer = 0.0
		lancer_timer = 0.0
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
	
	# Arrête la musique de tension et joue le son de cassure
	if music_audio and music_audio.playing:
		music_audio.stop()
		
	if break_audio:
		break_audio.play()
		
	var gm = GameManager
	gm.vitJ = Vector2.ZERO
	# Réinitialise la sauvegarde de usure au respawn
	gm.lantern_usure_saved = 100.0
	gm.is_lanterne_saved = true
	gm.reset_combo()
	var tween := create_tween()
	tween.tween_property(filtre_mort, "color:a", 1.0, 0.1)
	
	await get_tree().create_timer(1).timeout
	
	if gm.has_respawn_point and gm.respawn_scene != get_tree().current_scene.scene_file_path:
		get_tree().change_scene_to_file.call_deferred(gm.respawn_scene)
	else:
		get_tree().reload_current_scene.call_deferred()
	is_lanterne = true


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
		
		was_on_floor = is_on_floor()
		was_on_wall = is_on_wall()
		previous_velocity = velocity
		return

	# --- 2. Gravité & Sol ---
	if is_on_floor():
		can_dash = true
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity += get_gravity() * delta

	# --- Wall Jump Timer ---
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta

	# --- 3. Déclenchement du Dash ---
	if Input.is_action_just_pressed("dash") and dash_cd_timer.is_stopped() and can_dash:
		runparticles.emitting = false
		force_lancer_lanterne = true
		wallparticles.emitting = false
		course_audio.stop()
		can_dash = false
		dash_timer = DASH_DURATION
		velocity.y = 0
		wall_jump_lock_timer = 0
		
		if dash_audio:
			dash_audio.play()
		
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
	
	if lantern_ready:
		if lancer_timer <= 0.0:
			force_lancer_lanterne = true
			lancer_timer = 0.0
		else:
			lancer_timer-=delta / Engine.time_scale
	# --- 4. Lancer de la lanterne & Visée ralentie ---
	if is_lanterne:
		if Input.is_action_pressed("lancer"):
			direction_lancer = input_lancer.normalized()
			aim_line.tracer(delta / Engine.time_scale, direction_lancer, force_lancer, impact_vitesse_initiale)
			if not lantern_ready:
				lancer_timer = LANCER_DURATION
				joystick_on.emit()
				if slowdown_audio and not slowdown_audio.playing:
					slowdown_audio.play()
			lantern_ready = true
		if lantern_ready and (force_lancer_lanterne or Input.is_action_just_released("lancer")):
			force_lancer_lanterne = false
			joystick_off.emit()
			aim_line.clear_points()
			pointeur.visible = false
			if slowdown_audio and slowdown_audio.playing:
				slowdown_audio.stop()
			lancer_lanterne()
			is_lanterne = false
			lantern_ready = false
			direction_lancer = Vector2.ZERO

	# --- 5. État lanterne ---
	if is_lanterne:
		anim_str = ""
		lumiere.visible = true
	else:
		anim_str = "_sans_lanterne"
		lumiere.visible = false

	# --- 6. Saut & Wall Jump (avec marges) ---
	jump_buffer_timer -= delta
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		runparticles.emitting = false
		wallparticles.emitting = false
		course_audio.stop()

	_update_wall_coyote(delta)

	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			jump()
		elif wall_coyote_timer > 0.0:
			wall_jump()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.3

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

	# --- 11. Détection de l'atterrissage ---
	if is_on_floor() and not was_on_floor:
		if land_audio:
			land_audio.play()
	
	# --- 12. Actualisation usure lanterne ---
	if lantern_usure > 0.0:
		lantern_usure = maxf(lantern_usure - delta * 100/lantern_duration, 0.0)

	# --- 12 bis. Mort lente ---
	_update_mort_lente(delta)
	
	# --- 12 ter. Gestion de la musique selon l'usure ---
	_update_music_volume()
	
	# --- 13. Lumière lanterne & Particules ---
# --- 13. Lumière lanterne & Particules ---
	var coef = get_coef_usure()
	if coef > 0.1:
		lumiere.set_texture_scale(1.5 + 6.5 * (coef - 0.1))
	else:
		lumiere.base_energy = coef * 10

	if not is_lanterne or lantern_usure <= 30.0:
		if lightparticle.emitting:
			lightparticle.emitting = false
	else:
		var ratio = clampf((lantern_usure - 30.0) / 70.0, 0.0, 1.0)
		var target_amount = int(initial_light_particle_amount * ratio)
		
		# On ne met à jour l'amount que s'il change pour éviter de réinitialiser le cycle en boucle
		if lightparticle.amount != target_amount:
			lightparticle.amount = target_amount
			
		if not lightparticle.emitting:
			lightparticle.emitting = true

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


func _update_music_volume() -> void:
	if is_dead or not music_audio:
		return

	# Si la lanterne est au-dessus de 30 %, on coupe la musique
	if lantern_usure > 70.0:
		if music_audio.playing:
			music_audio.stop()
	else:
		# Dès que l'usure passe sous les 30 %, on lance la musique
		if not music_audio.playing:
			music_audio.play()

		# Progression de 0.0 (à 30% d'usure) à 1.0 (à 0% d'usure)
		var progress := clampf((70.0 - lantern_usure) / 70.0, 0.0, 1.0)
		
		# Fondu logarithmique de -30 dB (faible) à 0 dB (fort)
		music_audio.volume_db = lerpf(-30.0, 0.0, progress)


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


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body is TileMapLayer or body is TileMap:
		die()

func jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0          # pas de double saut avec la marge
	jump_buffer_timer = 0.0
	if jump_audio:
		jump_audio.play()


func wall_jump() -> void:
	can_dash = true
	dash_timer = 0.0
	velocity.x = wall_normal_x * WALL_JUMP_HORIZONTAL_SPEED
	velocity.y = WALL_JUMP_VERTICAL_SPEED
	wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
	wall_coyote_timer = 0.0
	jump_buffer_timer = 0.0
	if jump_audio:
		jump_audio.play()


func _update_wall_coyote(delta: float) -> void:
	wall_coyote_timer -= delta
	if is_on_floor():
		return
	var n := _detect_wall()
	if n == 0.0:
		return
	# Pas de rafraîchissement si le joueur s'éloigne déjà du mur :
	# évite un second wall jump juste après le premier.
	if velocity.x * n <= 0.0:
		wall_normal_x = n
		wall_coyote_timer = WALL_COYOTE_TIME


func _detect_wall() -> float:
	var facing := -1.0 if animated_sprite.flip_h else 1.0
	for dir in [facing, -facing]:
		if test_move(global_transform, Vector2(dir * WALL_CHECK_DISTANCE, 0.0), _wall_col):
			var n := _wall_col.get_normal()
			if absf(n.x) > 0.7:   # un vrai mur, pas un sol ou un plafond
				return n.x
	return 0.0
