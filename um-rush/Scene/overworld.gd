extends Node2D

@export var bgm: AudioStream

func _ready():
	AudioManager.play_bgm(bgm)
	$CanvasLayer/Level1Button.pressed.connect(func():
		GameState.reset_game()
		_go_to_scene("res://Scene/opening_cut_scene.tscn")
	)
	$CanvasLayer/Level2Button.pressed.connect(func(): _go_to_scene("res://Scene/canteen.tscn"))
	$CanvasLayer/Level3Button.pressed.connect(func(): _go_to_scene("res://Scene/level3.tscn"))
	$CanvasLayer/Level4Button.pressed.connect(func(): _go_to_scene("res://Scene/level4.tscn"))
	$CanvasLayer/Level5Button.pressed.connect(func(): _go_to_scene("res://Scene/level5.tscn"))
	$CanvasLayer/MenuButton.pressed.connect(func(): _go_to_scene("res://Scene/main_menu.tscn"))

	_setup_level_locks()

func _setup_level_locks():
	var buttons = [
		$CanvasLayer/Level1Button,
		$CanvasLayer/Level2Button,
		$CanvasLayer/Level3Button,
		$CanvasLayer/Level4Button,
		$CanvasLayer/Level5Button
	]
	
	var unlocked = GameState.get("unlocked_levels")
	if unlocked == null:
		unlocked = 1
		
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	
	for i in range(buttons.size()):
		var level_num = i + 1
		var btn = buttons[i]
		if level_num > unlocked:
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", transparent_style)
			
			# Create a visual lock overlay
			var overlay = ColorRect.new()
			overlay.name = "LockOverlay"
			overlay.color = Color(0.1, 0.1, 0.1, 0.6)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(overlay)
			
			var lock_label = Label.new()
			lock_label.text = "🔒 LOCKED"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", 16)
			lock_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			lock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			lock_label.add_theme_constant_override("outline_size", 4)
			lock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.add_child(lock_label)
		else:
			btn.disabled = false
			var old_overlay = btn.get_node_or_null("LockOverlay")
			if old_overlay:
				btn.remove_child(old_overlay)
				old_overlay.queue_free()

func _go_to_scene(scene_path: String) -> void:
	call_deferred("_change_scene", scene_path)

func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

