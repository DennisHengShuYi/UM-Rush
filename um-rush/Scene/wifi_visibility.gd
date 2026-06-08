extends Node

var overlay: ColorRect
var wifi_label: Label
var wifi_bar: ProgressBar
var wifi_bar_style: StyleBoxFlat
var wifi_strength := 100.0
const DRAIN_RATE = 15.0
const RECOVER_RATE = 8.0
var in_weak_zone := false
var disruption_timer := 0.0

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var canvas: CanvasLayer = get_parent().get_node("CanvasLayer")

	# WiFi label
	wifi_label = Label.new()
	wifi_label.text = "WiFi:"
	wifi_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	wifi_label.add_theme_font_size_override("font_size", 25)
	wifi_label.position = Vector2(50, 60)
	wifi_label.size = Vector2(110, 25)
	canvas.add_child(wifi_label)

	# WiFi bar
	wifi_bar_style = StyleBoxFlat.new()
	wifi_bar_style.bg_color = Color(0.0, 0.9, 0.2)
	wifi_bar = ProgressBar.new()
	wifi_bar.max_value = 100
	wifi_bar.value = 100
	wifi_bar.show_percentage = false
	wifi_bar.position = Vector2(165, 65)
	wifi_bar.size = Vector2(200, 25)
	wifi_bar.add_theme_stylebox_override("fill", wifi_bar_style)
	canvas.add_child(wifi_bar)

	# Dark overlay — simulates poor visibility
	overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.size = Vector2(1280, 720)
	overlay.position = Vector2(-20, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(overlay)

	# Weak WiFi warning label
	var warn = Label.new()
	warn.name = "WifiWarnLabel"
	warn.text = "📶 WEAK WIFI! CAN'T SEE OBSTACLES! 📶"
	warn.add_theme_font_size_override("font_size", 42)
	warn.add_theme_color_override("font_color", Color(0.0, 0.9, 0.2))
	warn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1))
	warn.add_theme_constant_override("outline_size", 8)
	warn.add_theme_constant_override("shadow_offset_x", 3)
	warn.add_theme_constant_override("shadow_offset_y", 3)
	warn.position = Vector2(100, 280)
	warn.size = Vector2(1080, 60)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.visible = false
	canvas.add_child(warn)

func set_weak_zone(weak: bool) -> void:
	in_weak_zone = weak

func trigger_disruption(duration: float = 2.0) -> void:
	disruption_timer = duration

func _process(delta: float) -> void:
	if disruption_timer > 0.0:
		disruption_timer -= delta

	var is_weak = in_weak_zone or (disruption_timer > 0.0)
	if is_weak:
		wifi_strength = max(wifi_strength - DRAIN_RATE * delta, 0.0)
	else:
		wifi_strength = min(wifi_strength + RECOVER_RATE * delta, 100.0)

	wifi_bar.value = wifi_strength

	# Update bar color
	if wifi_strength <= 25.0:
		wifi_bar_style.bg_color = Color(1.0, 0.0, 0.0)
	elif wifi_strength <= 50.0:
		wifi_bar_style.bg_color = Color(1.0, 0.5, 0.0)
	else:
		wifi_bar_style.bg_color = Color(0.0, 0.9, 0.2)

	# Darkness overlay gets stronger as wifi weakens
	var darkness = (1.0 - wifi_strength / 100.0) * 0.85
	overlay.color = Color(0.0, 0.0, 0.0, darkness)

	# Show warning when weak
	var warn = get_parent().get_node("CanvasLayer/WifiWarnLabel")
	if is_instance_valid(warn):
		warn.visible = wifi_strength <= 30.0

	# Game over if wifi hits zero
	if wifi_strength <= 0.0:
		set_process(false)
		overlay.color = Color(0.0, 0.0, 0.0, 0.9)
		get_parent().game_over("📶 No WiFi — completely blind!\nStay near the router next time.")
