extends Area2D

@export var level_id := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not _is_in_same_lane(body):
		return
	var parent := get_parent()
	if parent and parent.has_method("collect_cat"):
		parent.collect_cat(level_id)
	queue_free()

func _is_in_same_lane(body: Node) -> bool:
	var parent := get_parent()
	if not parent:
		return true
	var parent_lanes = parent.get("lanes")
	var player_lane = body.get("current_lane")
	if parent_lanes == null or player_lane == null:
		return true
	var player_lane_y = parent_lanes[player_lane]
	return abs(position.y - player_lane_y) < 100.0

