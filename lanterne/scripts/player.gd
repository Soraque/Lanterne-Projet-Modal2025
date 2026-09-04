extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_cd_timer: Timer = $DashCdTimer
@onready var camera_2d: Camera2D = $Camera2D

const SPEED = 400.0
const JUMP_VELOCITY = -600.0
const ACCELERATION = 6000.0
const FRICTION = 13000.0
const AIR_CONTROL = 7000.0

# Dash
const DASH_SPEED = 1500.0
const DASH_DURATION = 0.14
const DASH_COOLDOWN = 0.5
var dash_timer := 0.0

# Jump
var jump_buffer = false
var jump_available = false
var jbuffertime = 0.1

# Degats
var isInvincible = false
var invincible_time = 1.0


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
	var direction := Input.get_axis("left", "right")

	# 1. Gestion du Dash en cours
	if dash_timer > 0.0:
		dash_timer -= delta
		var looking_direction := -1.0 if animated_sprite.flip_h else 1.0
		velocity.x = looking_direction * DASH_SPEED
		velocity.y = 0
		
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
		
		if dash_timer <= 0.0:
			velocity.x = looking_direction * SPEED
			
		move_and_slide()
		return

	# 2. Gravité & Sol
	if not is_on_floor():
		jump_available = false
		velocity += get_gravity() * delta
	else:
		jump_available = true
		if jump_buffer:
			jump()

	# 3. Déclenchement du Dash
	if Input.is_action_just_pressed("dash") and dash_cd_timer.is_stopped():
		dash_timer = DASH_DURATION
		animated_sprite.play("dash")
		dash_cd_timer.start(DASH_COOLDOWN)

	# 4. Saut & Saut Variable
	if Input.is_action_just_pressed("jump"):
		jump()
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.3

	# 5. Mouvement horizontal
	if direction != 0:
		var accel = ACCELERATION if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, direction * SPEED, accel * delta)
	else:
		var friction = FRICTION if is_on_floor() else AIR_CONTROL * 0.5
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# 6. Orientation du Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# 7. Animations hors-dash
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			# Empêche de relancer "fall" si on est déjà en "fall" ou "chute longue"
			if animated_sprite.animation != "fall" and animated_sprite.animation != "chute longue":
				animated_sprite.play("fall")

	move_and_slide()


func on_jump_buffer_timeout() -> void:
	jump_buffer = false

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "fall":
		animated_sprite.play("chute longue")
