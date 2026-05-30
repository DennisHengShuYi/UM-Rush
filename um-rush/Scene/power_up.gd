extends Area2D

@export var power_type := "stress"
@export var calm_texture: Texture2D
@export var speed_texture: Texture2D
@export var shield_texture: Texture2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual()

func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var camera_x = camera.get_screen_center_position().x
	if position.x < camera_x - 1600.0:
		queue_free()

func _apply_visual() -> void:
	var sprite := get_node_or_null("Sprite2D")
	var label := get_node_or_null("NameLabel")
	if sprite == null:
		return
	if power_type == "speed":
		sprite.texture = speed_texture
		sprite.modulate = Color(1, 1, 1, 1)
		if label:
			label.text = "SPEED"
	elif power_type == "shield":
		sprite.texture = shield_texture
		sprite.modulate = Color(1, 1, 1, 1)
		if label:
			label.text = "SHIELD"
	else:
		sprite.texture = calm_texture
		sprite.modulate = Color(1, 1, 1, 1)
		if label:
			label.text = "CALM"

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not _is_in_same_lane(body):
		return
	var parent := get_parent()
	if parent and parent.has_method("collect_powerup"):
		parent.collect_powerup(power_type)
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
