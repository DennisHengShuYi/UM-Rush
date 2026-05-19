extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -600.0
const GRAVITY = 800.0
const DASH_SPEED = 900.0        # ← dash speed
const DASH_DURATION = 0.2       # ← how long dash lasts (seconds)
const DASH_COOLDOWN = 1.0       # ← wait time before can dash again

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Dash cooldown countdown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Trigger dash — press Shift key
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		# Dash in direction player is facing
		var direction = Input.get_axis("ui_left", "ui_right")
		dash_direction = direction if direction != 0 else (1.0 if not anim.flip_h else -1.0)

	# While dashing
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		if dash_timer <= 0:
			is_dashing = false

	# Normal movement when not dashing
	if not is_dashing:
		# Jump
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
