extends Control

# Drag and drop your 6 panel images here
@export var panel_images: Array[Texture2D]

@onready var panel_display = $panel_image
@onready var dialogue_text = $dialogue_box/dialogue_text
@onready var sfx_alarm = $SFX_Alarm
@onready var sfx_run = $SFX_Run

var current_panel: int = 0

var cutscene_text: Array[String] = [
	"07:52 AM... Azri's dorm room.",
	"*BEEP! BEEP! BEEP!*",
	"...Wait. TODAY is the final exam?!",
	"No no no... please tell me the exam isn't this morning... \nWhere's my exam schedule?!",
	"FINAL EXAM - DEWAN TUN CANSELOR - 8:00 AM. \nOMG! I only have 8 minutes left!",
	"No bus. No time. No choice.\nJUST RUSH!"
]

func _ready():
	AudioManager.stop_bgm()
	show_panel(current_panel)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		advance_cutscene()

func show_panel(index: int):
	if index < panel_images.size():
		panel_display.texture = panel_images[index]
	
	if index < cutscene_text.size():
		dialogue_text.text = cutscene_text[index]
	
	# Control alarm sound
	if index < 5:
		if not sfx_alarm.playing:
			sfx_alarm.play()
	else:
		sfx_alarm.stop()
		sfx_run.play()

func advance_cutscene():
	current_panel += 1

	if current_panel < cutscene_text.size():
		show_panel(current_panel)
	else:
		finish_cutscene()

func finish_cutscene():
	get_tree().change_scene_to_file("res://Scene/game.tscn")
