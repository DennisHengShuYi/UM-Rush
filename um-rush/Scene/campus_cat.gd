extends Area2D

@export var level_id := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	var parent := get_parent()
	if parent and parent.has_method("collect_cat"):
		parent.collect_cat(level_id)
	queue_free()
