extends Node2D
class_name Level_default

signal enemy_died(dead_enemy : CharacterBody2D)

@export var spawn_area: Rect2
@export var enemy_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var map_bounds: Rect2

@onready var spawn_timer: Timer = $SpawnTimer
@onready var arrow_holder := $ArrowHolder
@onready var enemy_holder := $EnemyHolder
@onready var gem_holder := $GemHolder

var game_time : float
var player_ui
var enemy_list = []

func _ready() -> void:
	randomize()
	enemy_died.connect(_on_enemy_died)
	GetEnemies()
	spawn_timer.start()
	player_ui = get_tree().get_first_node_in_group("PlayerUI")

func get_camera_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var top_left := cam.global_position - viewport_size * 0.5
	return Rect2(top_left, viewport_size)
	
func _process(delta: float) -> void:
	game_time += delta
	player_ui.update_timer(game_time)

func get_offscreen_spawn_position() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var cam_center := cam.global_position
	var margin := 100.0
	var side := randi() % 4
	var spawn_pos: Vector2
	
	match side:
		0: # Top
			spawn_pos = Vector2(
				randf_range(cam_center.x - viewport_size.x * 0.5, cam_center.x + viewport_size.x * 0.5),
				cam_center.y - viewport_size.y * 0.5 - margin
			)
		1: # Bottom
			spawn_pos = Vector2(
				randf_range(cam_center.x - viewport_size.x * 0.5, cam_center.x + viewport_size.x * 0.5),
				cam_center.y + viewport_size.y * 0.5 + margin
			)
		2: # Left
			spawn_pos = Vector2(
				cam_center.x - viewport_size.x * 0.5 - margin,
				randf_range(cam_center.y - viewport_size.y * 0.5, cam_center.y + viewport_size.y * 0.5)
			)
		3: # Right
			spawn_pos = Vector2(
				cam_center.x + viewport_size.x * 0.5 + margin,
				randf_range(cam_center.y - viewport_size.y * 0.5, cam_center.y + viewport_size.y * 0.5)
			)
	
	return spawn_pos



func GetEnemies():
	enemy_list = []
	for child in enemy_holder.get_children():
		enemy_list.append(child)

func _on_enemy_died(enemy_that_died: CharacterBody2D):
	if enemy_list.has(enemy_that_died):
		enemy_list.erase(enemy_that_died)
	
	spawn_experience_gem(enemy_that_died.global_position)

func spawn_experience_gem(position: Vector2):
	if experience_gem_scene == null:
		return
	
	var gem = experience_gem_scene.instantiate()
	
	gem.setup(5, "default")
	gem.global_position = position
	gem_holder.add_child(gem)


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.global_position = get_offscreen_spawn_position()
	enemy_holder.add_child(enemy)
	enemy_list.append(enemy)

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
