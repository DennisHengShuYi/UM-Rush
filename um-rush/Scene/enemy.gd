extends Area2D

@export var speed := 260.0
@export var pattern := "straight"
@export var lane_height := 200.0
@export var amplitude := 90.0
@export var wave_frequency := 3.0

@onready var sprite = $AnimatedSprite2D

var start_y := 0.0
var alive_time := 0.0
var assigned_lane := -1

func _ready() -> void:
	add_to_group("enemies")
	start_y = position.y
	body_entered.connect(_on_body_entered)
	sprite.play("move")

func _process(delta: float) -> void:
	alive_time += delta
	position.x -= speed * delta
	if pattern == "wave":
		position.y = start_y + sin(alive_time * wave_frequency) * amplitude
	elif pattern == "lane_shift":
		position.y = start_y + sin(alive_time * 1.8) * lane_height

	var parent := get_parent()
	if parent and parent.get("lanes") != null:
		var parent_lanes = parent.get("lanes")
		if parent_lanes.size() >= 3:
			position.y = clamp(position.y, parent_lanes[0] - 150.0, parent_lanes[2] - 150.0)

	var camera := get_viewport().get_camera_2d()
	if camera and position.x < camera.get_screen_center_position().x - 1600.0:
		queue_free()

func _on_body_entered(body: Node) -> void:     	
	if body.name != "Player":
		print("not player, ignoring")
		return
	
	if not _is_in_same_lane(body):
		return
		
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
		
	if body.has_method("consume_shield") and body.consume_shield():
		return
	var parent := get_parent()
	if parent and parent.has_method("handle_enemy_hit"):
		parent.handle_enemy_hit(self)

func _is_in_same_lane(body: Node) -> bool:
	if assigned_lane != -1:
		return body.get("current_lane") == assigned_lane
	var parent := get_parent()
	if not parent:
		return true

	var parent_lanes = parent.get("lanes")
	var player_lane = body.get("current_lane")
	if parent_lanes == null or player_lane == null:
		return true

	var player_lane_y = parent_lanes[player_lane]
	return abs(position.y - player_lane_y) < 180.0

