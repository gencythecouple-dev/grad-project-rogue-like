extends Node2D
class_name Level

signal enemy_died(dead_enemy : CharacterBody2D)

@export var spawn_area: Rect2
@export var enemy_scene: PackedScene
@export var map_bounds: Rect2


@onready var spawn_timer: Timer = $SpawnTimer
@onready var arrow_holder := $ArrowHolder
@onready var enemy_holder := $EnemyHolder
var enemy_list = []

func _ready() -> void:
	randomize()
	enemy_died.connect(_on_enemy_died)
	GetEnemies()
	spawn_timer.start()


func get_camera_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var size := get_viewport_rect().size / cam.zoom
	var top_left := cam.global_position - size * 5
	return Rect2(top_left, size)


func get_offscreen_spawn_position() -> Vector2:
	var cam_rect := get_camera_rect()
	var margin := 64
	var spawn_pos: Vector2

	var min_x = map_bounds.position.x
	var max_x = map_bounds.position.x + map_bounds.size.x
	var min_y = map_bounds.position.y
	var max_y = map_bounds.position.y + map_bounds.size.y

	var side := randi() % 4
	match side:
		0: # top
			spawn_pos = Vector2(
				randf_range(max(cam_rect.position.x, min_x), min(cam_rect.position.x + cam_rect.size.x, max_x)),
				min_y - margin
			)
		1: # bottom
			spawn_pos = Vector2(
				randf_range(max(cam_rect.position.x, min_x), min(cam_rect.position.x + cam_rect.size.x, max_x)),
				max_y + margin
			)
		2: # left
			spawn_pos = Vector2(
				min_x - margin,
				randf_range(max(cam_rect.position.y, min_y), min(cam_rect.position.y + cam_rect.size.y, max_y))
			)
		3: # right
			spawn_pos = Vector2(
				max_x + margin,
				randf_range(max(cam_rect.position.y, min_y), min(cam_rect.position.y + cam_rect.size.y, max_y))
			)

	return spawn_pos





func get_random_spawn_position() -> Vector2:
	var x = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
	var y = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	return Vector2(x, y)

func GetEnemies():
	enemy_list = []
	for child in enemy_holder.get_children():
		enemy_list.append(child)


func _on_enemy_died(enemy_that_died: CharacterBody2D):
	if enemy_list.has(enemy_that_died):
		enemy_list.erase(enemy_that_died)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.global_position = get_offscreen_spawn_position()
	enemy_holder.add_child(enemy)
	enemy_list.append(enemy)
	
func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
