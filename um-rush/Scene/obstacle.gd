extends StaticBody2D

func _process(delta: float) -> void:
	var camera = get_viewport().get_camera_2d()

	if camera == null:
		return

	var camera_x = camera.get_screen_center_position().x

	if position.x < camera_x - 1600:
		queue_free()
