extends Node

const FILL_RATE = 4.0
const DRAIN_RATE = 15.0

var noise := 0.0

var noise_bar: ProgressBar
var noise_label: Label
var loud_label: Label
var noise_bar_style: StyleBoxFlat

func _ready() -> void:
	_build_ui()
	if not InputMap.has_action("tiptoe"):
		InputMap.add_action("tiptoe")
		var ev := InputEventKey.new()
		ev.keycode = KEY_SHIFT
		InputMap.action_add_event("tiptoe", ev)

func _build_ui() -> void:
	var canvas: CanvasLayer = get_parent().get_node("CanvasLayer")

	noise_label = Label.new()
	noise_label.text = "Noise:"
	noise_label.add_theme_color_override("font_color", Color(0.06, 0.23, 0.59))
	noise_label.add_theme_font_size_override("font_size", 25)
	noise_label.position = Vector2(50, 60)
	noise_label.size = Vector2(110, 25)
	canvas.add_child(noise_label)

	noise_bar_style = StyleBoxFlat.new()
	noise_bar_style.bg_color = Color(0.0, 0.9, 0.2)

	noise_bar = ProgressBar.new()
	noise_bar.max_value = 100
	noise_bar.value = 0
	noise_bar.show_percentage = false
	noise_bar.position = Vector2(165, 65)
	noise_bar.size = Vector2(200, 25)
	noise_bar.add_theme_stylebox_override("fill", noise_bar_style)
	canvas.add_child(noise_bar)

	loud_label = Label.new()
	loud_label.text = "📚 TOO LOUD! HOLD SHIFT TO TIPTOE! 📚"
	loud_label.add_theme_font_size_override("font_size", 42)
	loud_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	loud_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1))
	loud_label.add_theme_constant_override("outline_size", 8)
	loud_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1))
	loud_label.add_theme_constant_override("shadow_offset_x", 3)
	loud_label.add_theme_constant_override("shadow_offset_y", 3)
	loud_label.position = Vector2(100, 280)
	loud_label.size = Vector2(1080, 60)
	loud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loud_label.visible = false
	canvas.add_child(loud_label)

func add_noise(amount: float) -> void:
	noise = clamp(noise + amount, 0.0, 100.0)

func _process(delta: float) -> void:
	if Input.is_action_pressed("tiptoe"):
		noise = max(noise - DRAIN_RATE * delta, 0.0)
	else:
		noise = min(noise + FILL_RATE * delta, 100.0)
		var player = get_parent().get_node_or_null("Player")
		if player and abs(player.velocity.x) > 50.0:
			noise = min(noise + FILL_RATE * 1.5 * delta, 100.0)

	if noise >= 100.0:
		noise = 100.0
		loud_label.visible = false
		set_process(false)
		get_parent().game_over("🤫 The librarian kicked you out!\nBe quieter next time.")
		return

	noise_bar.value = noise
	loud_label.visible = noise >= 70.0

	if noise >= 75.0:
		noise_bar_style.bg_color = Color(1.0, 0.0, 0.0)
	elif noise >= 50.0:
		noise_bar_style.bg_color = Color(1.0, 0.5, 0.0)
	else:
		noise_bar_style.bg_color = Color(0.0, 0.9, 0.2)
