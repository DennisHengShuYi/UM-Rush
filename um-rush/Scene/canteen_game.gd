extends Node2D

@export var bgm: AudioStream

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
@onready var hunger_meter = $HungerMeter
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var sfx_cat = $SFX_Cat
@onready var sfx_gameover = $SFX_GameOver
@onready var sfx_win = $SFX_Win
@onready var sfx_food = $SFX_Food
@onready var sfx_powerup = $SFX_PowerUp
@onready var score_state = get_node("/root/GameState")

enum RunState { MENU, PLAYING, GAME_OVER, WIN }
var state = RunState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var obstacle2_scene = preload("res://Scene/obstacle_2.tscn")
var goal_scene = preload("res://Scene/goal2.tscn")
var food_scene = preload("res://Scene/food.tscn")
var enemy_scene = preload("res://Scene/enemy.tscn")
var power_up_scene = preload("res://Scene/power_up.tscn")
var campus_cat_scene = preload("res://Scene/campus_cat.tscn")

var last_spawn_x = 0.0
var spawn_distance = 950.0
var last_food_x = 0.0
var food_spawn_distance = 1200.0
var last_enemy_x = 0.0
var enemy_spawn_distance = 2200.0
var last_powerup_x = 0.0
var powerup_spawn_distance = 3000.0
var cat_spawned = false
var cat_spawn_distance = 16500.0

var stress = 0.0
var max_stress = 100.0

var time_left = 60.0
var game_running = true

var start_x = 0.0
var goal_distance = 40000.0
var goal_spawned = false

var lanes = [-200.0, 0.0, 200.0]
var score_label: Label
var shield_label: Label

func _ready():
	AudioManager.play_bgm(bgm)
	stress_bar.max_value = max_stress
	stress_bar.value = 0
	win_popup.visible = false
	gameover_popup.visible = false
	_build_score_ui()
	_build_shield_ui()
	score_state.score_changed.connect(_on_score_changed)
	next_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = false
	player.hit_obstacle.connect(_on_player_hit_obstacle)
	_show_start_notice()
	start_game()

func _build_score_ui():
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(900, 2)
	score_label.size = Vector2(300, 32)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 25)
	score_label.add_theme_color_override("font_color", Color(0.06, 0.23, 0.59))
	$CanvasLayer.add_child(score_label)

func _build_shield_ui():
	shield_label = Label.new()
	shield_label.visible = false
	shield_label.text = "Shield: 0s"
	shield_label.position = Vector2(745, 34)
	shield_label.size = Vector2(150, 32)
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shield_label.add_theme_font_size_override("font_size", 25)
	shield_label.add_theme_color_override("font_color", Color(0.0, 0.55, 0.95))
	shield_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.9))
	shield_label.add_theme_constant_override("outline_size", 3)
	$CanvasLayer.add_child(shield_label)

func _update_shield_ui():
	if not shield_label:
		return
	var shield_time = player.get_shield_time_left()
	shield_label.visible = shield_time > 0.0
	if shield_label.visible:
		shield_label.text = "Shield: %ds" % int(ceil(shield_time))

func _on_score_changed(level_score: int, total_score: int):
	if score_label:
		score_label.text = "Score: %d | Total: %d" % [level_score, total_score]

var notice_label: Label
var notice_active = false

func _show_start_notice():
	var canvas = $CanvasLayer

	notice_label = Label.new()
	notice_label.text = "🍔 COLLECT FOOD OR YOUR SPEED DROPS! 🍔"
	notice_label.add_theme_font_size_override("font_size", 42)
	notice_label.add_theme_color_override("font_color", Color(1, 0.7, 0.0))
	notice_label.add_theme_color_override("font_outline_color", Color(0.2, 0.08, 0.0, 1))
	notice_label.add_theme_constant_override("outline_size", 6)
	notice_label.add_theme_constant_override("shadow_offset_x", 3)
	notice_label.add_theme_constant_override("shadow_offset_y", 3)
	notice_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	notice_label.position = Vector2(100, 280)
	notice_label.size = Vector2(1080, 60)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(notice_label)

	notice_active = true
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if is_instance_valid(notice_label):
			notice_label.queue_free()
		notice_active = false
	)

func start_game():
	score_state.start_level(2)
	state = RunState.PLAYING
	game_running = true
	time_left = 60.0
	stress = 0.0
	goal_spawned = false
	start_x = player.position.x
	last_spawn_x = player.position.x
	last_food_x = player.position.x
	last_enemy_x = player.position.x
	last_powerup_x = player.position.x
	cat_spawned = false

func _process(delta: float) -> void:
	if not game_running:
		return

	camera.global_position.x = player.global_position.x
	camera.global_position.y = 400.0
	time_left -= delta
	timer_label.text = "Time: " + str(int(time_left))
	_update_shield_ui()
	if time_left <= 0:
		time_left = 0
		game_over("⏰ You ran out of time!\nGet to class faster next time.")

	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"

	if stress >= max_stress:
		game_over("😵 Burned out from stress!\nTake it easy next time.")

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
		if player.position.x - last_food_x >= food_spawn_distance:
			last_food_x = player.position.x
			spawn_food()
		if player.position.x - last_enemy_x >= enemy_spawn_distance:
			last_enemy_x = player.position.x
			spawn_enemy("wave")
		if player.position.x - last_powerup_x >= powerup_spawn_distance:
			last_powerup_x = player.position.x
			spawn_powerup()
		if not cat_spawned and distance_travelled >= cat_spawn_distance:
			cat_spawned = true
			spawn_cat()

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

func spawn_food():
	var food = food_scene.instantiate()
	add_child(food)
	food.position = Vector2(player.position.x + 900.0, lanes[randi() % 3])

func spawn_goal():
	var goal = goal_scene.instantiate()
	add_child(goal)
	goal.position = Vector2(player.position.x + 2000, lanes[1])

func spawn_enemy(pattern: String = "wave"):
	var enemy = enemy_scene.instantiate()
	enemy.pattern = pattern
	enemy.speed = 260.0
	add_child(enemy)
	enemy.position = Vector2(player.position.x + 1200.0, lanes[randi() % 3])

func spawn_powerup():
	var power = power_up_scene.instantiate()
	power.power_type = ["stress", "speed", "shield"].pick_random()
	add_child(power)
	power.position = Vector2(player.position.x + 950.0, lanes[randi() % 3])

func spawn_cat():
	var cat = campus_cat_scene.instantiate()
	cat.level_id = 2
	add_child(cat)
	cat.position = Vector2(player.position.x + 1100.0, lanes[randi() % 3])

func collect_food():
	sfx_food.play()
	score_state.add_score(40)
	hunger_meter.eat_food()

func collect_powerup(power_type: String):
	score_state.record_powerup(power_type)
	if power_type == "stress":
		stress = 0.0
	elif power_type == "speed":
		player.apply_speed_boost()
	elif power_type == "shield":
		player.apply_shield()
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	sfx_powerup.play()

func collect_cat(level_id: int):
	if score_state.record_cat(level_id):
		sfx_cat.play()
		stress = max(stress - 10.0, 0.0)
		hunger_meter.eat_food()

func handle_enemy_hit(_enemy):
	score_state.record_hit()
	stress = clamp(stress + 25.0, 0, max_stress)
	if hunger_meter.has_method("eat_food"):
		hunger_meter.hunger = min(hunger_meter.hunger + 12.0, 100.0)
	if stress >= max_stress:
		game_over("The lunch rush knocked you off pace!")

func finish_level_score(prefix: String) -> String:
	score_state.finish_level({
		"distance": player.position.x - start_x,
		"time_left": time_left,
		"stress": stress
	})
	return score_state.format_level_result(prefix)

func win():
	state = RunState.WIN
	game_running = false
	player.set_physics_process(false)
	hunger_meter.set_process(false)
	hunger_meter.hungry_label.visible = false
	win_popup.visible = true
	sfx_win.play()
	if stress < 30:
		message_label.text = "🌟 Perfect! No stress at all!\nScore: A+"
	elif stress < 50:
		message_label.text = "🎉 Great job! Low stress!\nScore: A"
	elif stress < 80:
		message_label.text = "😅 Made it but quite stressed!\nScore: B"
	else:
		message_label.text = "😵 Barely survived!\nScore: C"
	message_label.text = finish_level_score("Escaped the canteen rush!")

func game_over(reason: String = ""):
	if state == RunState.GAME_OVER:
		return
	state = RunState.GAME_OVER
	game_running = false
	player.set_physics_process(false)
	hunger_meter.set_process(false)
	hunger_meter.hungry_label.visible = false
	gameover_popup.visible = true
	sfx_gameover.play()
	if stress >= max_stress:
		gameover_message.text = "😵 Burned out from stress!\nTake it easy next time."
	elif time_left <= 0:
		gameover_message.text = "⏰ You ran out of time!\nGet to class faster next time."
	else:
		gameover_message.text = reason if reason != "" else "😵 Game Over!"

func _on_next_level_pressed():
	get_tree().change_scene_to_file("res://Scene/level3.tscn")

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _input(event):
	pass

func _on_pause_button_pressed():
	pause_menu.toggle_pause()

func _on_player_hit_obstacle():
	if player.consume_shield():
		return
	score_state.record_hit()
	stress = clamp(stress + 40.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!\nTake it easy next time.")
