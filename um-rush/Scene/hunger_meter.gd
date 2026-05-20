extends Node

const FILL_RATE = 2.5
const FOOD_RESTORE = 35.0

var hunger := 0.0

var hunger_bar: ProgressBar
var hunger_label: Label
var hungry_label: Label
var hunger_bar_style: StyleBoxFlat

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var canvas: CanvasLayer = get_parent().get_node("CanvasLayer")

	hunger_label = Label.new()
	hunger_label.text = "Hungry:"
	hunger_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.0))
	hunger_label.add_theme_font_size_override("font_size", 25)
	hunger_label.position = Vector2(50, 65)
	hunger_label.size = Vector2(110, 25)
	canvas.add_child(hunger_label)

	hunger_bar_style = StyleBoxFlat.new()
	hunger_bar_style.bg_color = Color(0.9, 0.6, 0.1)

	hunger_bar = ProgressBar.new()
	hunger_bar.max_value = 100
	hunger_bar.value = 0
	hunger_bar.show_percentage = false
	hunger_bar.position = Vector2(165, 65)
	hunger_bar.size = Vector2(200, 25)
	hunger_bar.add_theme_stylebox_override("fill", hunger_bar_style)
	canvas.add_child(hunger_bar)

	hungry_label = Label.new()
	hungry_label.text = "🍔 GRAB FOOD TO KEEP RUNNING! 🍔"
	hungry_label.add_theme_font_size_override("font_size", 42)
	hungry_label.add_theme_color_override("font_color", Color(1, 0.5, 0.0))
	hungry_label.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.0, 1))
	hungry_label.add_theme_constant_override("shadow_offset_x", 3)
	hungry_label.add_theme_constant_override("shadow_offset_y", 3)
	hungry_label.add_theme_constant_override("outline_size", 6)
	hungry_label.position = Vector2(100, 320)
	hungry_label.size = Vector2(1080, 60)
	hungry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hungry_label.visible = false
	canvas.add_child(hungry_label)

func eat_food() -> void:
	hunger = max(hunger - FOOD_RESTORE, 0.0)

func _process(delta: float) -> void:
	hunger += FILL_RATE * delta

	if hunger >= 100.0:
		hunger = 100.0
		hungry_label.visible = false
		set_process(false)
		get_parent().game_over("🍔 Too hungry to run!\nGrab food next time.")
		return

	hunger_bar.value = hunger
	hungry_label.visible = hunger >= 70.0

	var player = get_parent().get_node("Player")
	if hunger >= 75.0:
		player.speed_mult = 0.4
		hunger_bar_style.bg_color = Color(1.0, 0.15, 0.15)
	elif hunger >= 50.0:
		player.speed_mult = 0.7
		hunger_bar_style.bg_color = Color(1.0, 0.8, 0.0)
	else:
		player.speed_mult = 1.0
		hunger_bar_style.bg_color = Color(0.9, 0.6, 0.1)
