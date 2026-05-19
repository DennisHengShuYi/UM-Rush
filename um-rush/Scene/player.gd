extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
const GRAVITY = 800.0
const DASH_SPEED = 800.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col = $CollisionShape2D

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0
var is_rolling = false

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Trigger dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_dashing and not is_rolling:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		var direction = Input.get_axis("ui_left", "ui_right")
		dash_direction = direction if direction != 0 else (1.0 if not anim.flip_h else -1.0)

	# Dash movement
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			is_dashing = false

	# Trigger roll — down arrow on floor
	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling and not is_dashing:
		is_rolling = true
		anim.play("Rolling")
		# Disable obstacle collision during roll
		set_collision_mask_value(3, false)
		anim.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)

	# Normal movement when not dashing or rolling
	if not is_dashing and not is_rolling:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			velocity.x = direction * SPEED
			anim.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Animation
		if not is_on_floor():
			anim.play("Jumping")
		elif direction != 0:
			anim.play("Running")
		else:
			anim.play("Idle")

	move_and_slide()

func _on_roll_finished():
	is_rolling = false
	# Restore obstacle collision
	set_collision_mask_value(3, true)
