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
@onready var alarm_snooze = $AlarmSnooze
@onready var pause_menu = $PauseLayer/PauseMenu
@onready var sfx_cat = $SFX_Cat
@onready var sfx_gameover = $SFX_GameOver
@onready var sfx_win = $SFX_Win
@onready var sfx_powerup = $SFX_PowerUp
@onready var score_state = get_node("/root/GameState")

enum RunState { MENU, PLAYING, GAME_OVER, WIN }
var state = RunState.MENU

var desk_scene = preload("res://Scene/obstacle.tscn")
var obstacle2_scene = preload("res://Scene/obstacle_2.tscn")
var goal_scene = preload("res://Scene/goal.tscn")
var enemy_scene = preload("res://Scene/enemy.tscn")
var power_up_scene = preload("res://Scene/power_up.tscn")
var campus_cat_scene = preload("res://Scene/campus_cat.tscn")

var last_spawn_x = 0.0
var spawn_distance = 1500.0
var last_enemy_x = 0.0
var enemy_spawn_distance = 3600.0
var last_powerup_x = 0.0
var powerup_spawn_distance = 3200.0
var cat_spawned = false
var cat_spawn_distance = 16000.0

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
var combo_label: Label
var last_distance_streak_x := 0.0

var shake_timer := 0.0
var shake_intensity := 15.0
var hit_flash_rect: ColorRect

func _ready():
	AudioManager.play_bgm(bgm)
	stress_bar.max_value = max_stress
	stress_bar.value = 0
	win_popup.visible = false
	gameover_popup.visible = false
	_build_score_ui()
	_build_shield_ui()
	_build_combo_ui()
	score_state.score_changed.connect(_on_score_changed)
	next_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	camera.drag_vertical_enabled = false
	camera.position_smoothing_enabled = false
	player.hit_obstacle.connect(_on_player_hit_obstacle)
	_build_hit_flash_ui()
	
	# Apply white outline for readability against bright backgrounds
	timer_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	timer_label.add_theme_constant_override("outline_size", 4)
	stress_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	stress_label.add_theme_constant_override("outline_size", 4)
	var lvl_lbl = $CanvasLayer.get_node_or_null("LevelLabel")
	if lvl_lbl:
		lvl_lbl.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
		lvl_lbl.add_theme_constant_override("outline_size", 4)

	start_game()

func _build_score_ui():
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.position = Vector2(820, 2)
	score_label.size = Vector2(300, 32)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 25)
	score_label.add_theme_color_override("font_color", Color(0.06, 0.23, 0.59))
	score_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	score_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(score_label)

func _build_shield_ui():
	shield_label = Label.new()
	shield_label.visible = false
	shield_label.text = "Shield: 0s"
	shield_label.position = Vector2(820, 34)
	shield_label.size = Vector2(300, 32)
	shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shield_label.add_theme_font_size_override("font_size", 25)
	shield_label.add_theme_color_override("font_color", Color(0.0, 0.55, 0.95))
	shield_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.9))
	shield_label.add_theme_constant_override("outline_size", 3)
	$CanvasLayer.add_child(shield_label)

func _build_combo_ui():
	combo_label = Label.new()
	combo_label.text = "Streak: 0 (x1.0)"
	combo_label.position = Vector2(820, 34)
	combo_label.size = Vector2(300, 32)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.add_theme_font_size_override("font_size", 25)
	combo_label.add_theme_color_override("font_color", Color(0.06, 0.23, 0.59))
	combo_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	combo_label.add_theme_constant_override("outline_size", 4)
	$CanvasLayer.add_child(combo_label)

func _update_shield_ui():
	if not shield_label or not combo_label:
		return
	var shield_time = player.get_shield_time_left()
	shield_label.visible = shield_time > 0.0
	if shield_label.visible:
		shield_label.text = "Shield: %ds" % int(ceil(shield_time))
		combo_label.position = Vector2(820, 66)
	else:
		combo_label.position = Vector2(820, 34)

func _on_score_changed(level_score: int, total_score: int):
	if score_label:
		score_label.text = "Score: %d | Total: %d" % [level_score, total_score]
	if combo_label:
		combo_label.text = "Streak: %d (x%.1f)" % [score_state.streak, score_state.combo_multiplier]

func start_game():
	score_state.start_level(1)
	AudioManager.play_bgm(preload("res://assets/audio/bgm/bgm_L1.ogg"))
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
	last_distance_streak_x = player.position.x

func _process(delta: float) -> void:
	if not game_running:
		return

	camera.global_position.x = player.global_position.x
	camera.global_position.y = 400.0
	
	if shake_timer > 0.0:
		shake_timer -= delta
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		if shake_timer <= 0.0:
			camera.offset = Vector2.ZERO
			
	time_left -= delta
	timer_label.text = "Time: " + str(int(time_left))
	_update_shield_ui()
	alarm_snooze.set_pressure(1.8 if time_left <= 20.0 else 1.0)
	if time_left <= 0:
		time_left = 0
		game_over("⏰ You ran out of time!\nGet to class faster next time.")

	stress += 3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left"):
		stress -= 8 * delta
	stress = clamp(stress, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"

	# Distance streak tracking
	if player.position.x - last_distance_streak_x >= 500.0:
		last_distance_streak_x = player.position.x
		score_state.increase_streak(1)

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
			if player.position.x - last_enemy_x >= enemy_spawn_distance:
				last_enemy_x = player.position.x
				spawn_enemy("straight")
			if player.position.x - last_powerup_x >= powerup_spawn_distance:
				last_powerup_x = player.position.x
				spawn_powerup()
			if not cat_spawned and distance_travelled >= cat_spawn_distance:
				cat_spawned = true
				spawn_cat()

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

func get_safe_spawn_x(desired_x: float, lane_y: float, min_distance: float = 400.0) -> float:
	var safe_x = desired_x
	var collision = true
	var attempts = 0
	while collision and attempts < 15:
		collision = false
		for child in get_children():
			if child == null:
				continue
			var is_gameplay_object = false
			if child is Area2D or child is StaticBody2D:
				is_gameplay_object = true
			if is_gameplay_object:
				var y_diff = abs(child.position.y - lane_y)
				if y_diff < 50.0:
					if abs(child.position.x - safe_x) < min_distance:
						safe_x = max(safe_x, child.position.x + min_distance)
						collision = true
						break
				elif y_diff < 250.0:
					if abs(child.position.x - safe_x) < 250.0:
						safe_x = max(safe_x, child.position.x + 250.0)
						collision = true
						break
		attempts += 1
	return safe_x

func spawn_obstacle_at(spawn_x: float, spawn_y: float):
	spawn_x = get_safe_spawn_x(spawn_x, spawn_y, 450.0)
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
	goal.position = Vector2(player.position.x + 2000, lanes[0])  # bottom lane

func spawn_enemy(pattern: String = "straight"):
	var enemy = enemy_scene.instantiate()
	enemy.pattern = pattern
	enemy.speed = 240.0
	var lane_index = randi() % 3
	var lane_y = lanes[lane_index]
	var spawn_x = get_safe_spawn_x(player.position.x + 1200.0, lane_y, 500.0)
	add_child(enemy)
	enemy.position = Vector2(spawn_x, lane_y - 600.0)
	enemy.assigned_lane = lane_index

func spawn_powerup():
	var power = power_up_scene.instantiate()
	power.power_type = ["stress", "speed", "shield"].pick_random()
	var lane_y = lanes[randi() % 3]
	var spawn_x = get_safe_spawn_x(player.position.x + 950.0, lane_y, 400.0)
	add_child(power)
	power.position = Vector2(spawn_x, lane_y)

func spawn_cat():
	var cat = campus_cat_scene.instantiate()
	cat.level_id = 1
	var lane_y = lanes[randi() % 3]
	var spawn_x = get_safe_spawn_x(player.position.x + 1100.0, lane_y, 450.0)
	add_child(cat)
	cat.position = Vector2(spawn_x, lane_y)


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
		stress = max(stress - 10.0, 0.0)
		sfx_cat.play()

func handle_enemy_hit(_enemy):
	if state != RunState.PLAYING:
		return
	last_distance_streak_x = player.position.x
	score_state.record_hit()
	trigger_hit_effects()
	stress = clamp(stress + 25.0, 0, max_stress)
	if stress >= max_stress:
		game_over("You were overwhelmed by campus traffic!")

func _build_hit_flash_ui():
	hit_flash_rect = ColorRect.new()
	hit_flash_rect.color = Color(1.0, 0.0, 0.0, 0.0)
	hit_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(hit_flash_rect)

func trigger_hit_effects():
	shake_timer = 0.15
	if hit_flash_rect:
		hit_flash_rect.color.a = 0.4
		var tween = create_tween()
		tween.tween_property(hit_flash_rect, "color:a", 0.0, 0.2)

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
	alarm_snooze.set_process(false)
	alarm_snooze.zzz_label.visible = false
	win_popup.visible = true
	AudioManager.stop_bgm()
	sfx_win.play()
	if stress < 30:
		message_label.text = "🌟 Perfect! No stress at all!\nScore: A+"
	elif stress < 50:
		message_label.text = "🎉 Great job! Low stress!\nScore: A"
	elif stress < 80:
		message_label.text = "😅 Made it but quite stressed!\nScore: B"
	else:
		message_label.text = "😵 Barely survived!\nScore: C"
	message_label.text = finish_level_score("Made it to class awake!")

func game_over(reason: String = ""):
	if state != RunState.PLAYING:
		return
	state = RunState.GAME_OVER
	game_running = false
	player.set_physics_process(false)
	alarm_snooze.set_process(false)
	alarm_snooze.zzz_label.visible = false
	gameover_popup.visible = true
	AudioManager.stop_bgm()
	sfx_gameover.play()
	if stress >= max_stress:
		gameover_message.text = "😵 Burned out from stress!\nTake it easy next time."
	elif time_left <= 0:
		gameover_message.text = "⏰ You ran out of time!\nGet to class faster next time."
	else:
		gameover_message.text = reason if reason != "" else "😵 Game Over!"

func _on_next_level_pressed():
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.08, 0.08, 0.15, 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_layer.add_child(overlay)
	
	var label = Label.new()
	label.text = "Next stop: DTC Canteen!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.modulate.a = 0.0
	transition_layer.add_child(label)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(overlay, "color:a", 1.0, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Scene/canteen.tscn")

func _on_retry_pressed():
	get_tree().reload_current_scene()

func _input(event):
	pass

func _on_pause_button_pressed():
	pause_menu.toggle_pause()

func _on_player_hit_obstacle():
	if state != RunState.PLAYING:
		return
	last_distance_streak_x = player.position.x
	if player.consume_shield():
		return
	score_state.record_hit()
	trigger_hit_effects()
	stress = clamp(stress + 40.0, 0, max_stress)
	stress_bar.value = stress
	stress_label.text = "Stress: " + str(int(stress)) + "%"
	if stress >= max_stress:
		game_over("😵 Burned out from stress!\nTake it easy next time.")
