extends CharacterBody2D

const SPEED = 1000.0
const JUMP_VELOCITY = -500.0
const GRAVITY = 800.0
const DASH_SPEED = 800.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 1.0
const LANE_SPEED = 8.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col = $CollisionShape2D

var lanes = [-600.0, -400.0, -200.0]
var current_lane = 1
var target_y: float

var is_jumping = false
var jump_velocity_y = 0.0

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0

var is_rolling = false

signal hit_obstacle
var hit_cooldown = 0.0

func _ready():
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	target_y = lanes[current_lane]
	position.y = target_y

func _physics_process(delta: float) -> void:
	# Jump arc — manual Y, gravity-driven
	if is_jumping:
		jump_velocity_y += GRAVITY * delta
		position.y += jump_velocity_y * delta
		if position.y >= target_y:
			position.y = target_y
			jump_velocity_y = 0.0
			is_jumping = false
			set_collision_mask_value(1, true)
			set_collision_mask_value(3, true)
	else:
		# Smooth lane slide when grounded
		position.y = lerp(position.y, target_y, LANE_SPEED * delta)

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

	# Roll — only when grounded
	if Input.is_action_just_pressed("roll") and not is_jumping and not is_rolling and not is_dashing:
		is_rolling = true
		anim.play("Rolling")
		set_collision_mask_value(3, false)
		anim.animation_finished.connect(_on_roll_finished, CONNECT_ONE_SHOT)

	# Normal movement
	if not is_dashing and not is_rolling:
		# Jump
		if Input.is_action_just_pressed("ui_accept") and not is_jumping:
			is_jumping = true
			jump_velocity_y = JUMP_VELOCITY
			set_collision_mask_value(1, false)
			set_collision_mask_value(3, false)

		# Lane up
		if Input.is_action_just_pressed("ui_up") and not is_jumping:
			current_lane = max(0, current_lane - 1)
			target_y = lanes[current_lane]

		# Lane down
		if Input.is_action_just_pressed("ui_down") and not is_jumping:
			current_lane = min(2, current_lane + 1)
			target_y = lanes[current_lane]

		# Horizontal
		var direction := Input.get_axis("", "ui_right")
		if direction != 0:
			velocity.x = direction * SPEED
			anim.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Lock Y from move_and_slide
	var locked_y = position.y
	velocity.y = 0
	move_and_slide()
	position.y = locked_y

	# Obstacle hit detection
	if hit_cooldown > 0:
		hit_cooldown -= delta
	if get_slide_collision_count() > 0 and hit_cooldown <= 0 and not is_rolling and not is_jumping:
		hit_obstacle.emit()
		hit_cooldown = 1.0

	# Animation
	if is_jumping:
		anim.play("Jumping")
	elif is_rolling:
		pass
	elif is_dashing:
		anim.play("Running")
	elif Input.get_axis("ui_left", "ui_right") != 0:
		anim.play("Running")
	else:
		anim.play("Idle")

func _on_roll_finished():
	is_rolling = false
	set_collision_mask_value(3, true)
