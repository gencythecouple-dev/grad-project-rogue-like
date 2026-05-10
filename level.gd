extends Node2D
class_name Level_default

signal enemy_died(dead_enemy : CharacterBody2D)

@export var spawn_area: Rect2
@export var slime_scene: PackedScene
@export var slime2_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var map_bounds: Rect2

@onready var game_over_screen = $GameOver
@onready var spawn_timer: Timer = $SpawnTimer
@onready var magic_bullet_holder := $MagicBulletHolder
@onready var enemy_holder := $EnemyHolder
@onready var gem_holder := $GemHolder
@export var mage_scene: PackedScene
@export var rogue_scene: PackedScene
@export var warrior_scene: PackedScene
@export var plant_scene: PackedScene
@export var fire_totem_scene: PackedScene
@export var necromancer_scene: PackedScene


var horde_timer: float = 0.0
var horde_interval: float = 30.0
var game_time : float
var base_interval: float = 2.0
var player_ui
var player: CharacterBody2D
var enemy_list = []
var enemy_pool: Array = []
var slime_pool: Array = []
var slime2_pool: Array = []
var plant_pool: Array = []
const POOL_SIZE := 150
var necromancer_spawned: bool = false
var last_config_check: float = 0.0





func _ready() -> void:
	_spawn_player()
	add_to_group("MainScene")
	_create_pool()
	spawn_wave(current_spawn_config["count"])
	randomize()
	enemy_died.connect(_on_enemy_died)
	spawn_timer.start()
	player_ui = get_tree().get_first_node_in_group("PlayerUI")

func _spawn_player() -> void:
	var scene
	match GameData.selected_character:
		"mage": scene = mage_scene
		"rogue": scene = rogue_scene
		"warrior": scene = warrior_scene
	if scene == null:
		return
	
	player = scene.instantiate()
	player.global_position = Vector2(640, 360)
	add_child(player)

func get_camera_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var top_left := cam.global_position - viewport_size * 0.5
	return Rect2(top_left, viewport_size)
	
func _process(delta: float) -> void:
	game_time += delta
	horde_timer += delta
	player_ui.update_timer(game_time)
	_update_spawn_config()
	
	if game_time - last_config_check >= 5.0:
		last_config_check = game_time
		_update_spawn_config()
	
	if game_time >= 540 and not necromancer_spawned:
		spawn_necromancer()
		necromancer_spawned = true
	
	if horde_timer >= horde_interval:
		horde_timer = 0.0
		_spawn_horde()

func spawn_necromancer() -> void:
	if necromancer_scene == null:
		return
	
	var necro = necromancer_scene.instantiate()
	necro.global_position = get_offscreen_spawn_position()
	enemy_holder.add_child(necro)
	enemy_list.append(necro)


func _game_over() -> void:
	get_tree().paused = true

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


func _create_pool() -> void:
	_fill_pool(slime_scene, slime_pool, POOL_SIZE)
	_fill_pool(slime2_scene, slime2_pool, 50)
	_fill_pool(plant_scene, plant_pool, 50)

func _fill_pool(scene: PackedScene, pool: Array, size: int) -> void:
	if scene == null:
		return
	for i in range(size):
		var enemy = scene.instantiate()
		enemy_holder.add_child(enemy)
		enemy.hide()
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		pool.append(enemy)

func _get_from_pool(pool: Array) -> Node:
	for enemy in pool:
		if not enemy.visible:
			return enemy
	return null

func _on_enemy_died(enemy_that_died: CharacterBody2D) -> void:
	if enemy_list.has(enemy_that_died):
		enemy_list.erase(enemy_that_died)
	
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.total_kills += 1
		
		if player.vampirism > 0:
			player.current_hp = min(player.current_hp + player.vampirism, player.max_hp)
			player.health_bar.value = player.current_hp
	
	var exp_to_drop = enemy_that_died.exp_value
	var anim = "default"
	if exp_to_drop >= 3:
		anim = "tier2"
	if exp_to_drop >=10:
		anim = "tier3"
	
	call_deferred("spawn_experience_gem", enemy_that_died.global_position, exp_to_drop, anim)

func spawn_experience_gem(position: Vector2, exp_amount: int, anim: String = "default") -> void:
	if experience_gem_scene == null:
		return
	
	var gem = experience_gem_scene.instantiate()
	gem.setup(exp_amount, anim)
	gem.global_position = position
	gem_holder.add_child(gem)


func spawn_enemy() -> void:
	var enemy_types = current_spawn_config["enemies"]
	var chosen = enemy_types[randi() % enemy_types.size()]
	
	var enemy
	match chosen:
		"slime":
			enemy = _get_from_pool(slime_pool)
			if enemy == null:
				enemy = slime_scene.instantiate()
				enemy_holder.add_child(enemy)
				slime_pool.append(enemy)
		"slime2":
			enemy = _get_from_pool(slime2_pool)
			if enemy == null:
				enemy = slime2_scene.instantiate()
				enemy_holder.add_child(enemy)
				slime2_pool.append(enemy)
		"plant":
			enemy = _get_from_pool(plant_pool)
			if enemy == null:
				enemy = plant_scene.instantiate()
				enemy_holder.add_child(enemy)
				plant_pool.append(enemy)
	
	if enemy == null:
		return
	
	enemy.global_position = get_offscreen_spawn_position()
	enemy.show()
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	var enemy_level = get_enemy_level()
	enemy.SetStats(enemy_level)
	enemy_list.append(enemy)

func return_to_pool(enemy) -> void:
	if enemy_list.has(enemy):
		enemy_list.erase(enemy)
	enemy.velocity = Vector2.ZERO
	enemy.knockback_velocity = Vector2.ZERO
	enemy.is_dying = false
	enemy.hide()
	enemy.process_mode = Node.PROCESS_MODE_DISABLED

var spawn_table = [
	{"time": 0,   "count": 2,  "interval": 2.0, "enemies": ["slime"]},
	{"time": 60,  "count": 3,  "interval": 1.5, "enemies": ["slime"]},
	{"time": 120, "count": 4,  "interval": 1.2, "enemies": ["slime"]},
	{"time": 180, "count": 5,  "interval": 1.0, "enemies": ["slime", "plant"]},
	{"time": 240, "count": 6,  "interval": 0.8, "enemies": ["slime", "plant"]},
	{"time": 300, "count": 8,  "interval": 0.6, "enemies": ["slime2"]},
	{"time": 360, "count": 10, "interval": 0.4, "enemies": ["slime2"]},
	{"time": 420, "count": 15, "interval": 0.25, "enemies": ["slime2"]},
	{"time": 480, "count": 20, "interval": 0.15, "enemies": ["slime2"]},
	{"time": 540, "count": 30, "interval": 0.1, "enemies": ["slime2"]},]

var current_spawn_config = spawn_table[0]

func get_enemy_level() -> int:
	if game_time < 120:
		return 1
	elif game_time < 240:
		return 2
	elif game_time < 360:
		return 3
	elif game_time < 480:
		return 4
	else:
		return 5


func _update_spawn_config() -> void:
	for config in spawn_table:
		if game_time >= config["time"]:
			current_spawn_config = config

func spawn_wave(count: int) -> void:
	for i in range(count):
		spawn_enemy()

func _spawn_horde() -> void:
	var player_pos = get_tree().get_first_node_in_group("Player").global_position
	var horde_angle = randf() * TAU
	for i in range(20):
		var enemy = _get_from_pool(slime_pool)
		if enemy == null:
			enemy = slime_scene.instantiate()
			enemy_holder.add_child(enemy)
			slime_pool.append(enemy)
		
		var spread = randf_range(-0.3, 0.3)
		var pos = player_pos + Vector2(cos(horde_angle + spread), sin(horde_angle + spread)) * 550
		enemy.global_position = pos
		enemy.show()
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.SetStats(get_enemy_level())
		enemy_list.append(enemy)


func show_game_over(player: CharacterBody2D) -> void:
	get_tree().paused = true
	game_over_screen.setup(
		game_time,
		player.total_kills,
		player.total_damage_dealt,
		player.total_exp_collected
	)
	game_over_screen.show()



func _on_spawn_timer_timeout() -> void:
	spawn_wave(current_spawn_config["count"])
	spawn_timer.wait_time = current_spawn_config["interval"]
	spawn_timer.start()
