extends Node2D

@export var bgm: AudioStream

func _ready():
	AudioManager.play_bgm(bgm)
	$CanvasLayer/Level1Button.pressed.connect(func():
		GameState.reset_game()
		_go_to_scene("res://Scene/game.tscn")
	)
	$CanvasLayer/Level2Button.pressed.connect(func(): _go_to_scene("res://Scene/canteen.tscn"))
	$CanvasLayer/Level3Button.pressed.connect(func(): _go_to_scene("res://Scene/level3.tscn"))
	$CanvasLayer/Level4Button.pressed.connect(func(): _go_to_scene("res://Scene/level4.tscn"))
	$CanvasLayer/Level5Button.pressed.connect(func(): _go_to_scene("res://Scene/level5.tscn"))
	$CanvasLayer/MenuButton.pressed.connect(func(): _go_to_scene("res://Scene/main_menu.tscn"))

func _go_to_scene(scene_path: String) -> void:
	call_deferred("_change_scene", scene_path)

func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
