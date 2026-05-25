extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		print("ESC WORKS")
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused

	if get_tree().paused:
		show()
	else:
		hide()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:   
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
