extends Control

@export var bgm: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_bgm(bgm)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_game_button_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://Scene/overworld.tscn")


func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/how_to_play.tscn")


func _on_credit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/credit.tscn")
