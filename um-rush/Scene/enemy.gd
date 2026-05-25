extends Area2D

@export var speed := 260.0
@export var pattern := "straight"
@export var lane_height := 200.0
@export var amplitude := 90.0
@export var wave_frequency := 3.0

var start_y := 0.0
var alive_time := 0.0

func _ready() -> void:
	start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	alive_time += delta
	position.x -= speed * delta
	if pattern == "wave":
		position.y = start_y + sin(alive_time * wave_frequency) * amplitude
	elif pattern == "lane_shift":
		position.y = start_y + sin(alive_time * 1.8) * lane_height

	var camera := get_viewport().get_camera_2d()
	if camera and position.x < camera.get_screen_center_position().x - 1200.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not _is_in_same_lane(body):
		return
	if body.has_method("consume_shield") and body.consume_shield():
		queue_free()
		return
	var parent := get_parent()
	if parent and parent.has_method("handle_enemy_hit"):
		parent.handle_enemy_hit(self)
	queue_free()

func _is_in_same_lane(body: Node) -> bool:
	var parent := get_parent()
	if not parent:
		return true

	var parent_lanes = parent.get("lanes")
	var player_lane = body.get("current_lane")
	if parent_lanes == null or player_lane == null:
		return true

	var closest_lane := 0
	var closest_distance := INF
	for i in range(parent_lanes.size()):
		var distance = abs(position.y - parent_lanes[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_lane = i

	return player_lane == closest_lane
