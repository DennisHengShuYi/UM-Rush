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
@onready var qna_mechanic = $QnaMechanic

enum GameState { MENU, PLAYING, GAME_OVER, WIN }
var state = GameState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var obstacle2_scene = preload("res://Scene/obstacle_2.tscn")
var goal_scene = preload("res://Scene/goal2.tscn")

var last_spawn_x = 0.0
var spawn_distance = 800.0
var stress = 0.0
var max_stress = 100.0
var time_left = 60.0
var game_running = true
var start_x = 0.0
var goal_distance = 40000.0
var goal_spawned = false
var lanes = [-200.0, 0.0, 200.0]

var next_question_x = 6000.0
var question_spacing = 5000.0
var question_active = false

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
	_show_start_notice()
	start_game()

var notice_label: Label

func _show_start_notice():
	var canvas = $CanvasLayer
	notice_label = Label.new()
	notice_label.text = "📝 FINAL EXAM! ANSWER CORRECTLY OR FACE MORE OBSTACLES! 📝"
	notice_label.add_theme_font_size_override("font_size", 32)
	notice_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	notice_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1))
	notice_label.add_theme_constant_override("outline_size", 8)
	notice_label.position = Vector2(100, 280)
	notice_label.size = Vector2(1080, 60)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(notice_label)
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if is_instance_valid(notice_label):
			notice_label.queue_free()
	)

func start_game():
	state = GameState.PLAYING
	game_running = true
	time_left = 60.0
	stress = 0.0
	goal_spawned = false
	start_x = player.position.x
	last_spawn_x = player.position.x

func _process(delta: float) -> void:
	if not game_running or question_active:
		return
	camera.global_position.x = player.global_position.x
	camera.global_position.y = 400.0
	time_left -= delta
	timer_label.text = "Time: " + str(int(time_left))
	if time_left <= 0:
		time_left = 0
		game_over("⏰ You ran out of time!")
	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!")
	var distance_travelled = player.position.x - start_x
	if distance_travelled >= goal_distance and not goal_spawned:
		goal_spawned = true
		spawn_goal()
	if Input.is_action_pressed("ui_right") and not goal_spawned:
		var distance_to_goal = goal_distance - (player.position.x - start_x)
		if distance_to_goal > 800:
			if player.position.x - last_spawn_x >= spawn_distance:
				last_spawn_x = player.position.x
				spawn_obstacles()
		if player.position.x + 1000 >= next_question_x:
			next_question_x += question_spacing
			show_question()

func show_question():
	question_active = true
	player.set_physics_process(false)
	qna_mechanic.ask_question()

func on_correct_answer():
	question_active = false
	player.set_physics_process(true)

func on_wrong_answer():
	question_active = false
	player.set_physics_process(true)
	# Spawn extra obstacle wave as punishment
	spawn_obstacle_at(player.position.x + 600.0, lanes[0])
	spawn_obstacle_at(player.position.x + 600.0, lanes[2])
	spawn_obstacle_at(player.position.x + 1000.0, lanes[1])
	stress = clamp(stress + 20.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"

var last_was_double = false

func spawn_obstacles():
	var spawn_x = player.position.x + 1000.0
	var roll = randf()
	if last_was_double:
		last_was_double = false
		spawn_obstacle_at(spawn_x, lanes[[0, 2].pick_random()])
		return
	if roll < 0.60:
		var lane_roll = randf()
		if lane_roll < 0.25:
			spawn_obstacle_at(spawn_x, lanes[0])
		elif lane_roll < 0.75:
			spawn_obstacle_at(spawn_x, lanes[1])
		else:
			spawn_obstacle_at(spawn_x, lanes[2])
	else:
		spawn_obstacle_at(spawn_x, lanes[0])
		spawn_obstacle_at(spawn_x + 400.0, lanes[2])
		spawn_obstacle_at(spawn_x + 1100.0, lanes[1])
		last_was_double = true

func spawn_obstacle_at(spawn_x: float, spawn_y: float):
	var obs = desk_scene.instantiate() if randi() % 2 == 0 else obstacle2_scene.instantiate()
	add_child(obs)
	obs.position = Vector2(spawn_x, spawn_y)

func spawn_goal():
	var goal = goal_scene.instantiate()
	add_child(goal)
	goal.position = Vector2(player.position.x + 2000, lanes[1])

func win():
	state = GameState.WIN
	game_running = false
	player.set_physics_process(false)
	qna_mechanic.set_process(false)
	win_popup.visible = true
	if stress < 30:
		message_label.text = "🎓 Perfect score!\nYou aced the exam! Grade: A+"
	elif stress < 50:
		message_label.text = "🎓 Great job!\nGrade: A"
	elif stress < 80:
		message_label.text = "😅 Passed!\nGrade: B"
	else:
		message_label.text = "😵 Barely passed!\nGrade: C"

func game_over(reason: String = ""):
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	game_running = false
	player.set_physics_process(false)
	qna_mechanic.set_process(false)
	gameover_popup.visible = true
	gameover_message.text = reason if reason != "" else "😵 Game Over!"

func _on_next_level_pressed():
	get_tree().change_scene_to_file("res://Scene/overworld.tscn")

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _on_player_hit_obstacle():
	stress = clamp(stress + 40.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!")
