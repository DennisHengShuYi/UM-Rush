extends Node2D

func _ready():
	$CanvasLayer/Level1Button.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://Scene/game.tscn"))
	$CanvasLayer/Level2Button.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://Scene/canteen.tscn"))
	$CanvasLayer/Level3Button.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://Scene/level3.tscn"))
	$CanvasLayer/Level4Button.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://Scene/level4.tscn"))
	$CanvasLayer/Level5Button.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://Scene/level5.tscn"))
