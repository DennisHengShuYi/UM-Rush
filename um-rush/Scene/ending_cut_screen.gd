extends Control

# Drag and drop your 6 panel images here
@export var panel_images: Array[Texture2D]

@onready var panel_display = $panel_image
@onready var dialogue_text = $dialogue_box/dialogue_text

var current_panel: int = 0

var cutscene_text: Array[String] = [
	"I made it...just in time.",
	"Worth every second of the run."
]

func _ready():
	show_panel(current_panel)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		advance_cutscene()

func show_panel(index: int):
	if index < panel_images.size():
		panel_display.texture = panel_images[index]
	
	if index < cutscene_text.size():
		dialogue_text.text = cutscene_text[index]

func advance_cutscene():
	current_panel += 1

	if current_panel < cutscene_text.size():
		show_panel(current_panel)
	else:
		finish_cutscene()

func finish_cutscene():
	get_tree().change_scene_to_file("res://Scene/overworld.tscn")
