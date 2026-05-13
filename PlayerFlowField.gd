class_name PlayerFlowField
extends Node

const TILE_SIZE: int = 64
var player_grid_pos: Vector2i = Vector2i.ZERO
var player_world_pos: Vector2 = Vector2.ZERO
var dirty: bool = false

func update(player_pos: Vector2) -> void:
	var new_grid_pos := Vector2i(player_pos / TILE_SIZE)
	if new_grid_pos != player_grid_pos:
		player_grid_pos = new_grid_pos
		player_world_pos = player_pos
		dirty = true

func get_direction(from: Vector2) -> Vector2:
	return (player_world_pos - from).normalized()
