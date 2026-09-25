extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var lumiere: PointLight2D = $Fire_light
@onready var aim_line: Line2D = $Aim_line
@onready var pointeur: Polygon2D = $Pointeur
@export var lanterne_scene: PackedScene


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

var jump_buffer = false# Le jump buffer permet de mémoriser une pression de saut légèrement
# avant de toucher le sol, afin que le saut se déclenche à l'atterrissage.
var jump_available = false
var jbuffertime = 0.1

# --- Lanterne ---

@export var is_lanterne = true # Le joueur possède-t-il actuellement la lanterne ?
var lantern_ready = false
var direction_lancer = Vector2.ZERO
var anim_str = "" # Suffixe utilisé pour choisir les animations avec/sans lanterne.
var force_lancer = 600
var impact_vitesse_initiale = 0.4
# --- Dégâts / Invincibilité ---

var isInvincible = false
var invincible_time = 1.0

# --- Boost lors des collisions ---

# Ces variables servent à détecter une nouvelle collision avec le sol ou un mur

# et à appliquer un petit boost vertical dans certaines situations.

var was_on_floor = false
var was_on_wall = false
var collision_boost_cooldown = 0.1
const max_boost_speed = 380
var previous_velocity = Vector2(0,0)

#Time dilatation
signal joystick_on
signal joystick_off
@onready var filter_rect = $"../../Overall/grey_filter"

func _ready() -> void:
	# Initialise le paramètre du shader utilisé pour le flash du personnage.
	var mat = animated_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_modifier", 0.0)
		


func jump() -> void:
	if jump_available:
		# Le joueur est autorisé à sauter immédiatement.
		velocity.y = JUMP_VELOCITY
		jump_available = false
		jump_buffer = false
	else:
		# Si le saut n'est pas encore possible, on mémorise la demande
		# pendant un court instant (jump buffer).
		jump_buffer = true
		get_tree().create_timer(jbuffertime).timeout.connect(on_jump_buffer_timeout)


func _physics_process(delta: float) -> void:
	var direction_h := Input.get_axis("left", "right")
	var input_lancer := Input.get_vector("lancer left","lancer right","lancer up","lancer down")

	# --- 1. Gestion du Dash en cours ---
	# Pendant le dash, le mouvement normal et la gravité sont temporairement ignorés.
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = vitesse_debut + looking_direction * DASH_SPEED
		velocity.y=0
		
		if animated_sprite.animation != "dash"+anim_str:
			animated_sprite.play("dash"+anim_str)
		
		if dash_timer <= 0.0:
			# À la fin du dash, on conserve la vitesse horizontale initiale.
			velocity.x = vitesse_debut
			
		move_and_slide()
		return

	# --- 2. Gravité & Sol ---
	if not is_on_floor():
		jump_available = false
		velocity += get_gravity() * delta
	else:
		# Au sol, le joueur récupère son saut et son dash.
		can_dash = true
		jump_available = true
		
		# Si un saut a été demandé juste avant l'atterrissage,
		# on l'exécute immédiatement.
		if jump_buffer:
			jump()
	
	# --- Wall Jump ---
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta
	
	# --- 3. Déclenchement du Dash ---
	if Input.is_action_just_pressed("dash") and dash_cd_timer.is_stopped() and can_dash:
		can_dash = false
		dash_timer = DASH_DURATION
		velocity.y=0
		wall_jump_lock_timer=0
		
		# La direction du dash dépend de l'orientation actuelle du sprite.
		if is_on_wall() and not is_on_floor():
			vitesse_debut = 0
			looking_direction = get_wall_normal().x / abs(get_wall_normal().x)
		else:
			looking_direction = -int(animated_sprite.flip_h)*2+1
			if velocity.x*looking_direction>0: # Si dash dans le sens du mouvement
				vitesse_debut = velocity.x # On conserve la vitesse
			else:
				vitesse_debut = 0 #Sinon non
		
		animated_sprite.play("dash"+anim_str)
		dash_cd_timer.start(DASH_COOLDOWN)

	# --- 4. Lancer de la lanterne ---
	if is_lanterne:
		
		if input_lancer.length() > 0.2: # Le joystick est suffisamment incliné
			direction_lancer = input_lancer.normalized()
			aim_line.tracer(delta / Engine.time_scale, direction_lancer,force_lancer,impact_vitesse_initiale)
			if not lantern_ready:
				joystick_on.emit()
			lantern_ready = true
		elif lantern_ready: # Le joystick vient d'être relâché
			# On rétablit le temps normal avant de lancer la lanterne.
			joystick_off.emit()
			aim_line.clear_points()
			pointeur.visible = false
			
			lancer_lanterne()
			is_lanterne = false
			lantern_ready = false
			direction_lancer = Vector2.ZERO
	Engine.time_scale = Global.time_dilatation

	# --- 5. Mise à jour de l'état de la lanterne et des animations ---
	# Plutôt que de modifier chaque nom d'animation individuellement,
	# anim_str permet d'ajouter automatiquement le suffixe "_sans_lanterne".
	if is_lanterne:
		anim_str = ""
		lumiere.visible = true
	else:
		anim_str = "_sans_lanterne"
		lumiere.visible = false


	# --- 6. Saut & saut variable ---
	if Input.is_action_just_pressed("jump"):
		jump()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		# Relâcher rapidement le bouton coupe la montée et permet
		# de contrôler la hauteur du saut.
		velocity.y *= 0.3
	
	# --- Wall Jump ---
	if Input.is_action_just_pressed("jump") and is_on_wall() and not is_on_floor():
		# get_wall_normal() pointe dans la direction opposée au mur.
		var wall_normal = get_wall_normal()
		
		velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
		velocity.y = WALL_JUMP_VERTICAL_SPEED
		
		# Pendant quelques frames, le contrôle horizontal est bloqué.
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
		
		jump_buffer = false
		jump_available = false
	
	# --- 7. Mouvement horizontal ---
	if wall_jump_lock_timer > 0.0:
		# Pendant le début du wall jump, on conserve la vitesse imposée
		# pour empêcher le joueur de revenir im	médiatement vers le mur.
		pass
	elif direction_h != 0:
			# Le joueur contrôle davantage son déplacement au sol qu'en l'air.
		var accel = ACCELERATION if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, direction_h * SPEED, accel * delta)
	else:
		# Sans input, la friction ramène progressivement la vitesse à zéro.
		var friction = FRICTION if is_on_floor() else AIR_CONTROL * 0.5
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# --- 8. Orientation du Sprite ---
	if direction_h > 0:
		animated_sprite.flip_h = false
	elif direction_h < 0:
		animated_sprite.flip_h = true

	# --- 9. Animations hors-dash ---
	if is_on_floor() and dash_timer<=0.0:
		if direction_h == 0:
			animated_sprite.play("idle"+anim_str)
		elif abs(direction_h)<0.4:
			# Une faible pression du joystick joue l'animation de marche
			# avec une vitesse proportionnelle à l'input.
			animated_sprite.play("marche"+anim_str,1.0*abs(direction_h)/0.4)
		else:
			animated_sprite.play("run"+anim_str,1.0*abs(direction_h))
	else:
		if is_on_wall():
			if velocity.y <= 0:
				animated_sprite.play("wall_slide_jump"+anim_str)
			else:
				# Empêche de relancer "fall" si on est déjà en "fall"
				# ou en "chute longue".
				if animated_sprite.animation != "wall_slide_fall"+anim_str and animated_sprite.animation != "wall_slide_grosse_chute":
					animated_sprite.play("wall_slide_fall"+anim_str)
		else:
			if velocity.y <= 0:
				animated_sprite.play("jump"+anim_str)
			else:
				# Même principe ici : on laisse l'animation de chute
				# se terminer avant de passer à la chute longue.
				if animated_sprite.animation != "fall"+anim_str and animated_sprite.animation != "chute longue":
					animated_sprite.play("fall"+anim_str)

	move_and_slide()
	
	if filter_rect and filter_rect.material:
			filter_rect.material.set_shader_parameter("desaturation_amount", 1-Global.time_dilatation)
			
			
	if collision_boost_cooldown>0 : collision_boost_cooldown -= delta
	

	# --- 10. Boost lors d'une collision avec un mur ---
	if collision_boost_cooldown>0 :
		collision_boost_cooldown -= delta

	var collision_count = get_slide_collision_count()
	if collision_count>0:
		for i in range(collision_count):
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()
			# A MODIFIER !!
			# Si on vient de toucher un mur, on peut appliquer un boost
			# vers le haut en fonction de la vitesse précédente.
			if ((is_on_wall() and not was_on_wall ) ) and collision_boost_cooldown<=0.0:
				if -previous_velocity.y<max_boost_speed and previous_velocity.y<0:
					velocity.y = -max_boost_speed
					collision_boost_cooldown = 0.1

	# Sauvegarde de l'état actuel pour pouvoir le comparer
	# à la prochaine frame.
	was_on_floor = is_on_floor()
	was_on_wall = is_on_wall()
	previous_velocity=velocity

func lancer_lanterne():
	# Crée une nouvelle lanterne à la position du joueur,
	# puis lui transmet la direction et la vitesse actuelles.
	var lanterne = lanterne_scene.instantiate()
	lanterne.global_position = global_position
	get_parent().add_child(lanterne)
	lanterne.lancer(direction_lancer,velocity,force_lancer,impact_vitesse_initiale)

func on_jump_buffer_timeout() -> void:
	# Si le joueur n'a pas pu sauter pendant la durée du buffer,
	# la demande de saut est annulée.
	jump_buffer = false

func _on_animated_sprite_2d_animation_finished() -> void:
	# Après l'animation de chute normale, on passe à la chute longue.
	if animated_sprite.animation == "fall"+anim_str:
		animated_sprite.play("chute longue"+anim_str)

	# Même logique pour la chute contre un mur.
	if animated_sprite.animation == "wall_slide_fall"+anim_str:
		animated_sprite.play("wall_slide_grosse_chute"+anim_str)
