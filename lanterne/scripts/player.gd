extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var lumiere: PointLight2D = $Fire_light
@onready var aim_line: Line2D = $Aim_line
@onready var pointeur: Polygon2D = $Pointeur
@onready var canvas_modulate_back : CanvasModulate = $background/CanvasModulate
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
var jump_buffer = false
var jump_available = false
var jbuffertime = 0.1

# --- Lanterne ---
@export var is_lanterne = true
var lantern_ready = false
@export var lantern_usure = 100 # Valeur de d'usure de la lanterne de 0 : éteinds à 100 : complètement allumé
var direction_lancer = Vector2.ZERO
var anim_str = ""
var force_lancer = 1000
var impact_vitesse_initiale = 0.2

# --- Dégâts / Invincibilité ---
var isInvincible = false
var invincible_time = 1.0

# --- Boost lors des collisions ---
var was_on_floor = false
var was_on_wall = false
var collision_boost_cooldown = 0.1
const max_boost_speed = 380
var previous_velocity = Vector2(0, 0)

# Time dilatation
signal joystick_on
signal joystick_off
@onready var filter_rect = $"../../Overall/grey_filter"


func _ready() -> void:
	# Téléportation au feu de camp si un checkpoint existe
	var gm = get_game_manager()
	if gm.has_respawn_point and gm.respawn_scene == get_tree().current_scene.scene_file_path:
		global_position = gm.respawn_position

	var mat = animated_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_modifier", 0.0)


func jump() -> void:
	if jump_available:
		velocity.y = JUMP_VELOCITY
		jump_available = false
		jump_buffer = false
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
			
		move_and_slide()
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
		if input_lancer.length() > 0.2:
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
		jump()

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.3

	if Input.is_action_just_pressed("jump") and is_on_wall() and not is_on_floor():
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
		velocity.y = WALL_JUMP_VERTICAL_SPEED
		wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
		jump_buffer = false
		jump_available = false

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

	# --- 9. Animations ---
	if is_on_floor() and dash_timer <= 0.0:
		if direction_h == 0:
			animated_sprite.play("idle" + anim_str)
		elif abs(direction_h) < 0.4:
			animated_sprite.play("marche" + anim_str, 1.0 * abs(direction_h) / 0.4)
		else:
			animated_sprite.play("run" + anim_str, 1.0 * abs(direction_h))
	else:
		if is_on_wall():
			if velocity.y <= 0:
				animated_sprite.play("wall_slide_jump" + anim_str)
			else:
				if animated_sprite.animation != "wall_slide_fall" + anim_str and animated_sprite.animation != "wall_slide_grosse_chute":
					animated_sprite.play("wall_slide_fall" + anim_str)
		else:
			if velocity.y <= 0:
				animated_sprite.play("jump" + anim_str)
			else:
				# Même principe ici : on laisse l'animation de chute
				# se terminer avant de passer à la chute longue.
				if animated_sprite.animation != "fall"+anim_str and animated_sprite.animation != "chute longue":
					animated_sprite.play("fall"+anim_str)
	
	move_and_slide()
	
	# --- 10. Actualisation usure lanterne ---
	if lantern_usure>0:
		lantern_usure-=delta*5
	else:
		is_lanterne = false
	
	# --- 11. Lumière lanterne ---
	var coef = get_coef_usure()
	if coef >0.1:
		lumiere.set_texture_scale(1.5 + 6.5*(coef-0.1))
	else:
		lumiere.base_energy=coef*10
	
	
	if filter_rect and filter_rect.material:
			filter_rect.material.set_shader_parameter("desaturation_amount", 1-Global.time_dilatation)
			
	if collision_boost_cooldown>0 : collision_boost_cooldown -= delta
	

	if filter_rect and filter_rect.material:
		filter_rect.material.set_shader_parameter("desaturation_amount", 1 - Global.time_dilatation)

	if collision_boost_cooldown > 0:
		collision_boost_cooldown -= delta

	# --- 10. Collision Wall Boost ---
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


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "fall" + anim_str:
		animated_sprite.play("chute longue" + anim_str)

	if animated_sprite.animation == "wall_slide_fall" + anim_str:
		animated_sprite.play("wall_slide_grosse_chute" + anim_str)


func die() -> void:
	var gm = get_game_manager()
	if gm.has_respawn_point and gm.respawn_scene != get_tree().current_scene.scene_file_path:
		get_tree().change_scene_to_file.call_deferred(gm.respawn_scene)
	else:
		get_tree().reload_current_scene.call_deferred()
	is_lanterne = true;


# --- Gestion du GameManager sans Autoload ---
func get_game_manager() -> Node:
	var root = get_tree().root
	var gm = root.get_node_or_null("GameManager")
	if not gm:
		# Crée le nœud GameManager s'il n'existe pas encore sous la racine
		gm = Node.new()
		gm.set_script(load("res://scripts/game_manager.gd"))
		gm.name = "GameManager"
		root.add_child.call_deferred(gm)
	return gm
	# Même logique pour la chute contre un mur.
	if animated_sprite.animation == "wall_slide_fall"+anim_str:
		animated_sprite.play("wall_slide_grosse_chute"+anim_str)

func get_coef_usure() -> float:
	var x = lantern_usure/100
	return (400*x**3 - 600*x**2 + 319*x)/119
