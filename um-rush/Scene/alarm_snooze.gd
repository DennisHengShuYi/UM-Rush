extends Node

# How fast sleepiness fills (units/sec). Reaches 100 in ~20s.
const FILL_RATE = 8.0
# How much each Space tap reduces sleepiness.
const TAP_REDUCE = 25.0
var sleepiness := 0.0

# UI created at runtime so no scene changes needed.
var sleep_bar: ProgressBar
var sleep_label: Label
var zzz_label: Label
var sleep_bar_style: StyleBoxFlat

func _ready() -> void:
	_build_ui()
	# Register snooze action if not already in project settings.
	if not InputMap.has_action("snooze"):
		InputMap.add_action("snooze")
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		InputMap.action_add_event("snooze", ev)

func _build_ui() -> void:
	var canvas: CanvasLayer = get_parent().get_node("CanvasLayer")

	sleep_label = Label.new()
	sleep_label.text = "Sleepy:"
	sleep_label.add_theme_color_override("font_color", Color(0.06, 0.23, 0.59))
	sleep_label.add_theme_font_size_override("font_size", 25)
	sleep_label.position = Vector2(50, 65)
	sleep_label.size = Vector2(110, 25)
	canvas.add_child(sleep_label)

	sleep_bar_style = StyleBoxFlat.new()
	sleep_bar_style.bg_color = Color(0.2, 0.6, 1.0)

	sleep_bar = ProgressBar.new()
	sleep_bar.max_value = 100
	sleep_bar.value = 0
	sleep_bar.show_percentage = false
	sleep_bar.position = Vector2(165, 65)
	sleep_bar.size = Vector2(200, 25)
	sleep_bar.add_theme_stylebox_override("fill", sleep_bar_style)
	canvas.add_child(sleep_bar)

	zzz_label = Label.new()
	zzz_label.text = "💤 PRESS SPACE TO STAY AWAKE! 💤"
	zzz_label.add_theme_font_size_override("font_size", 42)
	zzz_label.add_theme_color_override("font_color", Color(1, 0.9, 0.0))
	zzz_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	zzz_label.add_theme_constant_override("shadow_offset_x", 3)
	zzz_label.add_theme_constant_override("shadow_offset_y", 3)
	zzz_label.add_theme_constant_override("outline_size", 6)
	zzz_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.3, 1))
	zzz_label.position = Vector2(100, 320)
	zzz_label.size = Vector2(1080, 60)
	zzz_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zzz_label.visible = false
	canvas.add_child(zzz_label)

func _process(delta: float) -> void:
	sleepiness += FILL_RATE * delta

	if Input.is_action_just_pressed("snooze"):
		sleepiness -= TAP_REDUCE
		sleepiness = max(sleepiness, 0.0)

	if sleepiness >= 100.0:
		sleepiness = 100.0
		zzz_label.visible = false
		set_process(false)
		get_parent().game_over("😴 You fell asleep!\nSet more alarms next time.")
		return

	sleep_bar.value = sleepiness
	zzz_label.visible = sleepiness >= 70.0

	if sleepiness >= 80.0:
		sleep_bar_style.bg_color = Color(1.0, 0.15, 0.15)
	elif sleepiness >= 50.0:
		sleep_bar_style.bg_color = Color(1.0, 0.8, 0.0)
	else:
		sleep_bar_style.bg_color = Color(0.2, 0.6, 1.0)
