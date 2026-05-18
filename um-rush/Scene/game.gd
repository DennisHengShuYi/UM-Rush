extends Node2D

@onready var parallax: ParallaxBackground = $ParallaxBackground

var desk_scene = preload("res://Scene/obstacle.tscn")
var spawn_timer = 0.0
var spawn_interval = 2.0
var scroll_speed = 200.0

func _ready() -> void:
	print("game.gd loaded")
	print("parallax node: ", parallax)

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		print("RIGHT")
		parallax.scroll_offset.x -= scroll_speed * delta
	elif Input.is_action_pressed("ui_left"):
		print("LEFT")
		parallax.scroll_offset.x += scroll_speed * delta

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_desk()

func spawn_desk():
	var desk = desk_scene.instantiate()
	add_child(desk)
	desk.position = Vector2(1100, 530)
