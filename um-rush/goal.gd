extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		print("Goal reached!")
		get_tree().get_root().get_node("Game").win()
