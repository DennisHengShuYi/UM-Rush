extends Node2D

var desk_scene = preload("res://Scene/obstacle.tscn")
var spawn_timer = 0.0
var spawn_interval = 2.0

@onready var player = $Player

func _process(delta: float) -> void:
	# Only count timer when player is moving right
	if Input.is_action_pressed("ui_right"):
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_desk()

func spawn_desk():
	var desk = desk_scene.instantiate()
	add_child(desk)
	# Changed Y to match ground level
	desk.position = Vector2(player.position.x + 800, -68)
	print("Desk spawned at: ", desk.position)
