extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var lumiere: PointLight2D = $Fire_light
@export var lanterne_scene: PackedScene

const SPEED = 400.0
const JUMP_VELOCITY = -500.0
const ACCELERATION = 6000.0
const FRICTION = 13000.0
const AIR_CONTROL = 7000.0

# Dash
const DASH_SPEED = 1100.0
const DASH_DURATION = 0.09
const DASH_COOLDOWN = 0.35
var can_dash = true
var dash_timer := 0.0
var vitesse_debut = 0
var looking_direction = 0

# Jump
var jump_buffer = false
var jump_available = false
var jbuffertime = 0.1

# Lanterne
@export var is_lanterne = true #est ce que le joueur à la lanterne
var lantern_ready = false
var direction_lancer = Vector2.ZERO
var anim_str = "" # Nom des animation avec ou sans lanterne
const time_dilatation_strength = 0.5

# Degats
var isInvincible = false
var invincible_time = 1.0

#Collision_boost
var was_on_floor = false
var was_on_wall = false
var collision_boost_cooldown = 0.1
const max_boost_speed = 380
var previous_velocity = Vector2(0,0)

func _ready() -> void:
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
	var input_lancer := Input.get_vector("lancer left","lancer right","lancer up","lancer down")

	# 1. Gestion du Dash en cours
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = vitesse_debut + looking_direction * DASH_SPEED
		
		if animated_sprite.animation != "dash"+anim_str:
			animated_sprite.play("dash"+anim_str)
		
		if dash_timer <= 0.0:
			velocity.x = vitesse_debut
			
		move_and_slide()
		return

	# 2. Gravité & Sol
	if not is_on_floor():
		jump_available = false
		velocity += get_gravity() * delta
	else:
		can_dash = true
		jump_available = true
		if jump_buffer:
			jump()

	# 3. Déclenchement du Dash
	if Input.is_action_just_pressed("dash") and dash_cd_timer.is_stopped() and can_dash:
		can_dash = false
		dash_timer = DASH_DURATION
		vitesse_debut = velocity.x
		looking_direction = -int(animated_sprite.flip_h)*2+1
		animated_sprite.play("dash"+anim_str)
		dash_cd_timer.start(DASH_COOLDOWN)
	
	# 4. Déclenchement lancer de lanterne
	if is_lanterne:
		if input_lancer.length() > 0.2: # Le joystick est suffisamment incliné
			direction_lancer = input_lancer.normalized()
			lantern_ready = true
			Global.time_dilatation = 1-time_dilatation_strength*input_lancer.length()
			Engine.time_scale = Global.time_dilatation
			print(Global.time_dilatation)
		elif lantern_ready: # Le joystick vient d'être relâché
			Global.time_dilatation = 1
			Engine.time_scale = Global.time_dilatation

			lancer_lanterne()
			is_lanterne = false
			lantern_ready = false
			direction_lancer = Vector2.ZERO

	# 5. Màj des anims sans lanterne
	if is_lanterne:
		anim_str = ""
		lumiere.visible = true
	else:
		anim_str = "_sans_lanterne"
		lumiere.visible = false
	
	
	# 5. Saut & Saut Variable
	if Input.is_action_just_pressed("jump"):
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.3

	# 6. Mouvement horizontal
	if direction_h != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, direction_h * SPEED, accel * delta)
	else:
		var friction = FRICTION if is_on_floor() else AIR_CONTROL * 0.5
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# 7. Orientation du Sprite
	if direction_h > 0:
		animated_sprite.flip_h = false
	elif direction_h < 0:
		animated_sprite.flip_h = true

	# 8. Animations hors-dash
	
	if is_on_floor() and dash_timer<=0.0:
		if direction_h == 0:
			animated_sprite.play("idle"+anim_str)
		elif abs(direction_h)<0.4:
			animated_sprite.play("marche"+anim_str,1.0*abs(direction_h)/0.4)
		else:
			animated_sprite.play("run"+anim_str,1.0*abs(direction_h))
	else:
		if velocity.y <= 0:
			animated_sprite.play("jump"+anim_str)
		else:
			# Empêche de relancer "fall" si on est déjà en "fall" ou "chute longue"
			if animated_sprite.animation != "fall"+anim_str and animated_sprite.animation != "chute longue":
				animated_sprite.play("fall"+anim_str)

	move_and_slide()
	if collision_boost_cooldown>0 : collision_boost_cooldown -= delta
	
	var collision_count = get_slide_collision_count()
	if collision_count>0:
		for i in range(collision_count):
			var collision = get_slide_collision(i)
			var normal = collision.get_normal()
			var tangent = Vector2(-normal.y, normal.x)
			
			#A MODIFIERRR !!
			if ((is_on_wall() and not was_on_wall ) ) and collision_boost_cooldown<=0.0:
				#var boost_speed = ((abs(normal.dot(previous_velocity)))*(100)/(DASH_SPEED-SPEED) + max_boost_speed)
				#if boost_speed>max_boost_speed : boost_speed = max_boost_speed
				#var collision_boost = -max_boost_speed*tangent
				#print("collision_boost :", collision_boost)
				#print((boost_speed - previous_velocity.y))
				#if previous_velocity.y <= max_boost_speed:
					#velocity += -(boost_speed +  previous_velocity.y) * tangent
					#collision_boost_cooldown = 0.1
				if -previous_velocity.y<max_boost_speed and previous_velocity.y<0:
					velocity.y = -max_boost_speed
					print("go")
					collision_boost_cooldown = 0.1

	was_on_floor = is_on_floor()
	was_on_wall = is_on_wall()
	previous_velocity=velocity


func lancer_lanterne():
	var lanterne = lanterne_scene.instantiate()
	lanterne.global_position = global_position
	get_parent().add_child(lanterne)
	lanterne.lancer(direction_lancer,velocity)


func on_jump_buffer_timeout() -> void:
	jump_buffer = false

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "fall"+anim_str:
		animated_sprite.play("chute longue"+anim_str)
