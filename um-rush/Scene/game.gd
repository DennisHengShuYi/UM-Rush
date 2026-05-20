extends Node2D

@onready var stress_bar = $CanvasLayer/ProgressBar
@onready var timer_label = $CanvasLayer/Label
@onready var stress_label = $CanvasLayer/StressLabel
@onready var player = $Player
@onready var win_popup = $CanvasLayer/WinPopup
@onready var message_label = $CanvasLayer/WinPopup/VBoxContainer/MessageLabel
@onready var next_button = $CanvasLayer/WinPopup/VBoxContainer/NextLevelButton
@onready var gameover_popup = $CanvasLayer/GameOverPopup
@onready var gameover_message = $CanvasLayer/GameOverPopup/VBoxContainer/MessageLabel
@onready var retry_button = $CanvasLayer/GameOverPopup/VBoxContainer/RetryButton
@onready var camera = $Camera2D

enum GameState { MENU, PLAYING, GAME_OVER, WIN }
var state = GameState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var obstacle2_scene = preload("res://Scene/obstacle_2.tscn")
var goal_scene = preload("res://Scene/goal.tscn")

var last_spawn_x = 0.0
var spawn_distance = 800.0

var stress = 0.0
var max_stress = 100.0

var time_left = 60.0
var game_running = true

var start_x = 0.0
var goal_distance = 40000.0
var goal_spawned = false

# Lane Y positions — must match player.gd lanes array
var lanes = [-200.0, 0.0, 200.0]

func _ready():
	stress_bar.max_value = max_stress
	stress_bar.value = 0
	win_popup.visible = false
	gameover_popup.visible = false
	next_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = false
	player.hit_obstacle.connect(_on_player_hit_obstacle)
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
	camera.global_position.x = player.global_position.x
	camera.global_position.y = 400.0
	time_left -= delta
	timer_label.text = "Time: " + str(int(time_left))
	if time_left <= 0:
		time_left = 0
		game_over("⏰ You ran out of time!\nGet to class faster next time.")

	# Stress
	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"

	if stress >= max_stress:
		game_over("😵 Burned out from stress!\nTake it easy next time.")

	# Distance check → spawn goal
	var distance_travelled = player.position.x - start_x
	if distance_travelled >= goal_distance and not goal_spawned:
		goal_spawned = true
		spawn_goal()

	# Distance-based obstacle spawning
	if Input.is_action_pressed("ui_right") and not goal_spawned:
		var distance_to_goal = goal_distance - (player.position.x - start_x)
		if distance_to_goal > 800:
			if player.position.x - last_spawn_x >= spawn_distance:
				last_spawn_x = player.position.x
				spawn_obstacles()

# Picks how many lanes to fill, then spawns at the same X
var last_was_double = false

func spawn_obstacles():
	var spawn_x = player.position.x + 1000.0
	var roll = randf()

	# If last spawn was double (top+bottom+center), force single this time
	# and never pick center — prevents 3-lane cluster
	if last_was_double:
		last_was_double = false
		var lane_index = [0, 2].pick_random()  # only top or bottom
		spawn_obstacle_at(spawn_x, lanes[lane_index])
		return

	if roll < 0.60:
		# Weighted single lane — center 50%, top/bottom 25% each
		var lane_roll = randf()
		if lane_roll < 0.25:
			spawn_obstacle_at(spawn_x, lanes[0])
		elif lane_roll < 0.75:
			spawn_obstacle_at(spawn_x, lanes[1])
		else:
			spawn_obstacle_at(spawn_x, lanes[2])
	else:
		# Top + bottom, well separated so they don't visually stack
		spawn_obstacle_at(spawn_x,          lanes[0])
		spawn_obstacle_at(spawn_x + 400.0,  lanes[2])  # ← 400 so they don't look merged
		# Center follows after both are clearly past
		spawn_obstacle_at(spawn_x + 1100.0, lanes[1])
		last_was_double = true  # ← next spawn will be forced single on top or bottom only

func spawn_obstacle_at(spawn_x: float, spawn_y: float):
	var obs
	if randi() % 2 == 0:
		obs = desk_scene.instantiate()
	else:
		obs = obstacle2_scene.instantiate()
	add_child(obs)
	obs.position = Vector2(spawn_x, spawn_y)

func spawn_goal():
	var goal = goal_scene.instantiate()
	add_child(goal)
	goal.position = Vector2(player.position.x + 2000, lanes[1])  # bottom lane

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

func game_over(reason: String = ""):
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	game_running = false
	player.set_physics_process(false)
	gameover_popup.visible = true
	if stress >= max_stress:
		gameover_message.text = "😵 Burned out from stress!\nTake it easy next time."
	elif time_left <= 0:
		gameover_message.text = "⏰ You ran out of time!\nGet to class faster next time."
	else:
		gameover_message.text = reason if reason != "" else "😵 Game Over!"

func _on_next_level_pressed():
	get_tree().change_scene_to_file("res://Scene/canteen.tscn")

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _input(event):
	pass

func _on_player_hit_obstacle():
	stress = clamp(stress + 40.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!\nTake it easy next time.")
