extends Node2D

@onready var stress_bar = $CanvasLayer/ProgressBar
@onready var timer_label = $CanvasLayer/Label
@onready var stress_label = $CanvasLayer/StressLabel
@onready var player = $Player
@onready var win_popup = $CanvasLayer/WinPopup
@onready var message_label = $CanvasLayer/WinPopup/VBoxContainer/MessageLabel
@onready var next_button = $CanvasLayer/WinPopup/VBoxContainer/NextLevelButton

enum GameState { MENU, PLAYING, GAME_OVER, WIN }
var state = GameState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var goal_scene = preload("res://Scene/goal.tscn")

var last_spawn_x = 0.0
var spawn_distance = 1500.0

var stress = 0.0
var max_stress = 100.0

var time_left = 60.0
var game_running = true

var start_x = 0.0
var goal_distance = 10000.0
var goal_spawned = false

func _ready():
	stress_bar.max_value = max_stress
	stress_bar.value = 0
	win_popup.visible = false
	next_button.pressed.connect(_on_next_level_pressed)
	start_game()

func start_game():
	state = GameState.PLAYING
	game_running = true
	time_left = 60.0
	stress = 0.0
	goal_spawned = false
	start_x = player.position.x
	last_spawn_x = player.position.x

func _process(delta: float) -> void:
	if not game_running:
		return

	# Countdown timer
	time_left -= delta
	timer_label.text = "Time: " + str(int(time_left))
	if time_left <= 0:
		time_left = 0
		game_over()

	# Stress
	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"

	if stress >= max_stress:
		game_over()

	# Distance check → spawn goal
	var distance_travelled = player.position.x - start_x
	if distance_travelled >= goal_distance and not goal_spawned:
		goal_spawned = true
		spawn_goal()

	# Distance-based obstacle spawning
	if Input.is_action_pressed("ui_right") and not goal_spawned:
		if player.position.x - last_spawn_x >= spawn_distance:
			last_spawn_x = player.position.x
			spawn_desk()

func spawn_desk():
	var desk = desk_scene.instantiate()
	add_child(desk)
	desk.position = Vector2(player.position.x + 1000, -20)

func spawn_goal():
	var goal = goal_scene.instantiate()
	add_child(goal)
	goal.position = Vector2(player.position.x + 2000, 50)

func win():
	state = GameState.WIN
	game_running = false
	player.set_physics_process(false)
	win_popup.visible = true
	if stress < 30:
		message_label.text = "🌟 Perfect! No stress at all!\nScore: A+"
	elif stress < 50:
		message_label.text = "🎉 Great job! Low stress!\nScore: A"
	elif stress < 80:
		message_label.text = "😅 Made it but quite stressed!\nScore: B"
	else:
		message_label.text = "😵 Barely survived!\nScore: C"

func game_over():
	state = GameState.GAME_OVER
	game_running = false
	timer_label.text = "Burned Out! 😵 Press Space to retry"
	player.set_physics_process(false)

func _on_next_level_pressed():
	get_tree().change_scene_to_file("res://Scene/level2.tscn")

func _input(event):
	if state == GameState.GAME_OVER:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
