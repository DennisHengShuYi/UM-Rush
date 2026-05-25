extends CharacterBody2D

const SPEED = 1000.0
const JUMP_VELOCITY = -380.0
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

var speed_mult := 1.0
var power_speed_mult := 1.0
var speed_boost_timer := 0.0
var shield_timer := 0.0
var shield_visual: Node2D
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
	shield_visual = _create_shield_visual()
	shield_visual.visible = false

func _physics_process(delta: float) -> void:
	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			power_speed_mult = 1.0
	if shield_timer > 0:
		shield_timer -= delta
		if shield_timer <= 0:
			shield_timer = 0.0
	_update_shield_visual()

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
			velocity.x = direction * SPEED * speed_mult * power_speed_mult
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

func apply_speed_boost(multiplier: float = 1.5, duration: float = 5.0) -> void:
	power_speed_mult = multiplier
	speed_boost_timer = duration

func apply_shield(duration: float = 8.0) -> void:
	shield_timer = duration
	_update_shield_visual()

func consume_shield() -> bool:
	if shield_timer <= 0:
		return false
	shield_timer = 0.0
	_update_shield_visual()
	return true

func get_shield_time_left() -> float:
	return max(shield_timer, 0.0)

func _create_shield_visual() -> Node2D:
	var visual = Node2D.new()
	visual.name = "ShieldVisual"
	visual.z_index = 4
	visual.position = col.position

	var bubble = Polygon2D.new()
	bubble.name = "Bubble"
	bubble.color = Color(0.2, 0.7, 1.0, 0.18)
	var points := PackedVector2Array()
	for i in range(32):
		var angle = TAU * float(i) / 32.0
		points.append(Vector2(cos(angle) * 155.0, sin(angle) * 155.0))
	bubble.polygon = points
	visual.add_child(bubble)

	var ring = Line2D.new()
	ring.name = "Ring"
	ring.width = 10.0
	ring.default_color = Color(0.25, 0.9, 1.0, 0.85)
	ring.closed = true
	for i in range(40):
		var angle = TAU * float(i) / 40.0
		ring.add_point(Vector2(cos(angle) * 168.0, sin(angle) * 168.0))
	visual.add_child(ring)

	add_child(visual)
	return visual

func _update_shield_visual() -> void:
	if not shield_visual:
		return
	var active := shield_timer > 0.0
	shield_visual.visible = active
	if not active:
		return
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 120.0) * 0.04
	shield_visual.scale = Vector2(pulse, pulse)
