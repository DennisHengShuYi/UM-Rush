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
@onready var wifi_visibility = $WifiVisibility
@onready var score_state = get_node("/root/GameState")

enum RunState { MENU, PLAYING, GAME_OVER, WIN }
var state = RunState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var obstacle2_scene = preload("res://Scene/obstacle_2.tscn")
var goal_scene = preload("res://Scene/goal2.tscn")
var enemy_scene = preload("res://Scene/enemy.tscn")
var power_up_scene = preload("res://Scene/power_up.tscn")
var campus_cat_scene = preload("res://Scene/campus_cat.tscn")

var last_spawn_x = 0.0
var spawn_distance = 800.0
var last_enemy_x = 0.0
var enemy_spawn_distance = 2100.0
var last_powerup_x = 0.0
var powerup_spawn_distance = 3200.0
var cat_spawned = false
var cat_spawn_distance = 17500.0
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

# Weak WiFi zones — player enters these and visibility drops
var weak_zones = []
var next_zone_x = 3000.0
var zone_spacing = 4000.0

func _ready():
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
	score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	score_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(score_label)

func _build_shield_ui():
	shield_label = Label.new()
	shield_label.visible = false
	shield_label.text = "Shield: 0s"
	shield_label.position = Vector2(745, 2)
	shield_label.size = Vector2(150, 32)
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shield_label.add_theme_font_size_override("font_size", 25)
	shield_label.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
	shield_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	shield_label.add_theme_constant_override("outline_size", 4)
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

func _show_start_notice():
	var canvas = $CanvasLayer
	notice_label = Label.new()
	notice_label.text = "📶 FSKTM BUILDING! AVOID WEAK WIFI ZONES! 📶"
	notice_label.add_theme_font_size_override("font_size", 36)
	notice_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.2))
	notice_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1))
	notice_label.add_theme_constant_override("outline_size", 8)
	notice_label.add_theme_constant_override("outline_size", 6)
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
	score_state.start_level(4)
	state = RunState.PLAYING
	game_running = true
	time_left = 60.0
	stress = 0.0
	goal_spawned = false
	start_x = player.position.x
	last_spawn_x = player.position.x
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
		game_over("⏰ You ran out of time!")
	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!")

	# Check if player is in a weak WiFi zone
	var in_weak = false
	for zone in weak_zones:
		if player.position.x >= zone.x and player.position.x <= zone.x + zone.y:
			in_weak = true
			break
	wifi_visibility.set_weak_zone(in_weak)

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
			if player.position.x - last_enemy_x >= enemy_spawn_distance:
				last_enemy_x = player.position.x
				spawn_enemy("wave" if in_weak else "straight")
			if player.position.x - last_powerup_x >= powerup_spawn_distance:
				last_powerup_x = player.position.x
				spawn_powerup()
			if not cat_spawned and distance_travelled >= cat_spawn_distance:
				cat_spawned = true
				spawn_cat()
		# Spawn weak zones ahead of player
		if player.position.x + 2000 >= next_zone_x:
			spawn_weak_zone()

func spawn_weak_zone():
	# zone = Vector2(start_x, width)
	var zone_width = randf_range(1500.0, 3000.0)
	weak_zones.append(Vector2(next_zone_x, zone_width))
	next_zone_x += zone_spacing + zone_width

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

func spawn_enemy(pattern: String = "straight"):
	var enemy = enemy_scene.instantiate()
	enemy.pattern = pattern
	enemy.speed = 320.0 if wifi_visibility.in_weak_zone else 270.0
	add_child(enemy)
	enemy.position = Vector2(player.position.x + 1200.0, lanes[randi() % 3])

func spawn_powerup():
	var power = power_up_scene.instantiate()
	power.power_type = ["stress", "speed", "shield"].pick_random()
	add_child(power)
	power.position = Vector2(player.position.x + 950.0, lanes[randi() % 3])

func spawn_cat():
	var cat = campus_cat_scene.instantiate()
	cat.level_id = 4
	add_child(cat)
	cat.position = Vector2(player.position.x + 1100.0, lanes[randi() % 3])

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

func collect_cat(level_id: int):
	if score_state.record_cat(level_id):
		stress = max(stress - 10.0, 0.0)
		wifi_visibility.wifi_strength = min(wifi_visibility.wifi_strength + 25.0, 100.0)

func handle_enemy_hit(_enemy):
	score_state.record_hit()
	stress = clamp(stress + 30.0, 0, max_stress)
	wifi_visibility.set_weak_zone(true)
	if stress >= max_stress:
		game_over("Weak WiFi made the route impossible!")

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
	wifi_visibility.set_process(false)
	win_popup.visible = true
	if stress < 30:
		message_label.text = "📶 Full signal all the way!\nScore: A+"
	elif stress < 50:
		message_label.text = "📶 Good connection!\nScore: A"
	elif stress < 80:
		message_label.text = "😅 Spotty signal...\nScore: B"
	else:
		message_label.text = "😵 Barely connected!\nScore: C"
	message_label.text = finish_level_score("Kept enough signal to survive!")

func game_over(reason: String = ""):
	if state == RunState.GAME_OVER:
		return
	state = RunState.GAME_OVER
	game_running = false
	player.set_physics_process(false)
	wifi_visibility.set_process(false)
	# Add this — remove darkness so popup is visible
	wifi_visibility.overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	gameover_popup.visible = true
	gameover_message.text = reason if reason != "" else "😵 Game Over!"
	var warn = get_node_or_null("CanvasLayer/WifiWarnLabel")
	if warn:
		warn.visible = false

func _on_next_level_pressed():
	get_tree().change_scene_to_file("res://Scene/level5.tscn")

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _on_player_hit_obstacle():
	if player.consume_shield():
		return
	score_state.record_hit()
	stress = clamp(stress + 40.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	wifi_visibility.set_weak_zone(true)
	if stress >= max_stress:
		game_over("😵 Burned out from stress!")
