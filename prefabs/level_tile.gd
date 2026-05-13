extends TileMapLayer

@export var tile_size: int = 64

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var cam_pos := cam.global_position
		position = Vector2(
			floor(cam_pos.x / tile_size) * tile_size - 1920,
			floor(cam_pos.y / tile_size) * tile_size - 1080
		)
