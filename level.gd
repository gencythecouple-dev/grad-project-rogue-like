extends Node2D
class_name Level_default

signal enemy_died(dead_enemy : Area2D)

@export var spawn_area: Rect2
@export var slime_scene: PackedScene
@export var slime2_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var map_bounds: Rect2
@export var mage_scene: PackedScene
@export var rogue_scene: PackedScene
@export var warrior_scene: PackedScene
@export var plant_scene: PackedScene
@export var fire_totem_scene: PackedScene
@export var necromancer_scene: PackedScene
@export var death_boss_scene: PackedScene

@onready var game_over_screen = $GameOver
@onready var spawn_timer: Timer = $SpawnTimer
@onready var magic_bullet_holder := $MagicBulletHolder
@onready var enemy_holder := $EnemyHolder
@onready var gem_holder := $GemHolder
@onready var flow_field = $PlayerFlowField

const MAX_ENEMIES := 700

var horde_timer: float = 0.0
var horde_interval: float = 30.0
var directed_wave_timer: float = 0.0
var directed_wave_interval: float = 20.0
var game_time: float = 660.0
var player_ui
var player: CharacterBody2D
var enemy_list = []
var slime_pool: Array = []
var slime2_pool: Array = []
var plant_pool: Array = []
const POOL_SIZE := 300
var necromancer_spawned: bool = false
var death_boss_spawned: bool = false
var last_config_check: float = 0.0
var current_spawn_config = {}

var spawn_table = [
	{"time": 0,   "count": 5,  "interval": 1.0,  "enemies": ["slime"]},
	{"time": 30,  "count": 8,  "interval": 0.8,  "enemies": ["slime"]},
	{"time": 60,  "count": 10, "interval": 0.6,  "enemies": ["slime"]},
	{"time": 120, "count": 12, "interval": 0.4,  "enemies": ["slime", "plant"]},
	{"time": 180, "count": 15, "interval": 0.3,  "enemies": ["slime", "plant"]},
	{"time": 240, "count": 20, "interval": 0.2,  "enemies": ["slime", "plant"]},
	{"time": 300, "count": 25, "interval": 0.15, "enemies": ["slime2"]},
	{"time": 360, "count": 30, "interval": 0.1,  "enemies": ["slime2"]},
	{"time": 420, "count": 40, "interval": 0.08, "enemies": ["slime2"]},
	{"time": 480, "count": 50, "interval": 0.05, "enemies": ["slime2"]},
	{"time": 540, "count": 60, "interval": 0.05, "enemies": ["slime2"]},
]

func _ready() -> void:
	add_to_group("MainScene")
	current_spawn_config = spawn_table[0]
	_spawn_player()
	_create_pool()
	enemy_died.connect(_on_enemy_died)
	player_ui = get_tree().get_first_node_in_group("PlayerUI")
	spawn_wave(current_spawn_config["count"])
	spawn_timer.start()

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

func _process(delta: float) -> void:
	if player:
		flow_field.update(player.global_position)
	if Input.is_action_pressed("ui_focus_next") and Engine.get_frames_per_second() >= 20:
		_stress_spawn()
	game_time += delta
	horde_timer += delta
	directed_wave_timer += delta
	player_ui.update_timer(game_time)

	if game_time - last_config_check >= 5.0:
		last_config_check = game_time
		_update_spawn_config()

	if game_time >= 540 and not necromancer_spawned:
		necromancer_spawned = true
		spawn_necromancer()

	if game_time >= 660 and not death_boss_spawned:
		death_boss_spawned = true
		spawn_death_boss()

	if horde_timer >= horde_interval:
		horde_timer = 0.0
		_spawn_horde()

	if directed_wave_timer >= directed_wave_interval:
		directed_wave_timer = 0.0
		_spawn_directed_wave()

func get_camera_rect() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var top_left := cam.global_position - viewport_size * 0.5
	return Rect2(top_left, viewport_size)

func get_offscreen_spawn_position() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var cam_center := cam.global_position
	var margin := 100.0
	var side := randi() % 4
	var spawn_pos: Vector2
	match side:
		0:
			spawn_pos = Vector2(randf_range(cam_center.x - viewport_size.x * 0.5, cam_center.x + viewport_size.x * 0.5), cam_center.y - viewport_size.y * 0.5 - margin)
		1:
			spawn_pos = Vector2(randf_range(cam_center.x - viewport_size.x * 0.5, cam_center.x + viewport_size.x * 0.5), cam_center.y + viewport_size.y * 0.5 + margin)
		2:
			spawn_pos = Vector2(cam_center.x - viewport_size.x * 0.5 - margin, randf_range(cam_center.y - viewport_size.y * 0.5, cam_center.y + viewport_size.y * 0.5))
		3:
			spawn_pos = Vector2(cam_center.x + viewport_size.x * 0.5 + margin, randf_range(cam_center.y - viewport_size.y * 0.5, cam_center.y + viewport_size.y * 0.5))
	return spawn_pos

func _create_pool() -> void:
	_fill_pool(slime_scene, slime_pool, POOL_SIZE)
	_fill_pool(slime2_scene, slime2_pool, 150)
	_fill_pool(plant_scene, plant_pool, 100)

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

func _on_enemy_died(enemy_that_died: Area2D) -> void:
	if enemy_list.has(enemy_that_died):
		enemy_list.erase(enemy_that_died)
	if player:
		player.total_kills += 1
		if player.vampirism > 0:
			player.current_hp = min(player.current_hp + player.vampirism, player.max_hp)
			player.health_bar.value = player.current_hp
	var exp_to_drop = enemy_that_died.exp_value
	var anim = "default"
	if exp_to_drop >= 10:
		anim = "tier2"
	if exp_to_drop >= 15:
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
	if enemy_list.size() >= MAX_ENEMIES:
		return
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
	enemy.SetStats(get_enemy_level())
	enemy_list.append(enemy)

func _spawn_directed_wave() -> void:
	if player == null or enemy_list.size() >= MAX_ENEMIES:
		return
	var wave_count := int(clamp(game_time / 10.0, 10, 60))
	var angle := randf() * TAU
	for i in range(wave_count):
		if enemy_list.size() >= MAX_ENEMIES:
			break
		var enemy = _get_from_pool(slime_pool)
		if enemy == null:
			enemy = slime_scene.instantiate()
			enemy_holder.add_child(enemy)
			slime_pool.append(enemy)
		var spread := randf_range(-0.2, 0.2)
		var dist := randf_range(500, 700)
		enemy.global_position = player.global_position + Vector2(cos(angle + spread), sin(angle + spread)) * dist
		enemy.show()
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.SetStats(get_enemy_level())
		enemy_list.append(enemy)

func return_to_pool(enemy) -> void:
	if enemy_list.has(enemy):
		enemy_list.erase(enemy)
	enemy.velocity = Vector2.ZERO
	enemy.knockback_velocity = Vector2.ZERO
	enemy.is_dying = false
	enemy.hide()
	enemy.process_mode = Node.PROCESS_MODE_DISABLED

func spawn_wave(count: int) -> void:
	for i in range(count):
		spawn_enemy()

func _spawn_horde() -> void:
	if player == null:
		return
	var horde_pos := get_offscreen_spawn_position()
	for i in range(20):
		var enemy = _get_from_pool(slime_pool)
		if enemy == null:
			enemy = slime_scene.instantiate()
			enemy_holder.add_child(enemy)
			slime_pool.append(enemy)
		enemy.global_position = horde_pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		enemy.show()
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.SetStats(get_enemy_level())
		enemy_list.append(enemy)

func spawn_necromancer() -> void:
	if necromancer_scene == null:
		return
	var necro = necromancer_scene.instantiate()
	necro.global_position = get_offscreen_spawn_position()
	enemy_holder.add_child(necro)
	enemy_list.append(necro)

func spawn_death_boss() -> void:
	if death_boss_scene == null:
		return
	var boss = death_boss_scene.instantiate()
	boss.global_position = get_offscreen_spawn_position()
	enemy_holder.add_child(boss)

func get_enemy_level() -> int:
	if game_time < 120: return 1
	elif game_time < 240: return 2
	elif game_time < 360: return 3
	elif game_time < 480: return 4
	else: return 5

func _update_spawn_config() -> void:
	for config in spawn_table:
		if game_time >= config["time"]:
			current_spawn_config = config

func _game_over() -> void:
	get_tree().paused = true

func show_game_over(player: CharacterBody2D) -> void:
	get_tree().paused = true
	game_over_screen.setup(game_time, player.total_kills, player.total_damage_dealt, player.total_exp_collected)
	game_over_screen.show()

func get_enemy_quota() -> int:
	if game_time < 30: return 8
	elif game_time < 60: return 30
	elif game_time < 120: return 75
	elif game_time < 180: return 120
	elif game_time < 240: return 150
	elif game_time < 300: return 200
	elif game_time < 360: return 300
	elif game_time < 420: return 400
	elif game_time < 480: return 500
	elif game_time < 540: return 600
	else: return 700

func _spawn_enclosing_wave(count: int) -> void:
	if player == null:
		return
	var cam := get_viewport().get_camera_2d()
	var viewport_size := get_viewport_rect().size / cam.zoom
	var min_dist := viewport_size.length() * 0.5 + 120.0
	var max_dist := min_dist + 200.0
	var dominant_angle := randf() * TAU
	var heavy_count := int(count * 0.65)
	var light_count := count - heavy_count

	for i in range(heavy_count):
		if enemy_list.size() >= MAX_ENEMIES:
			break
		var spread := randf_range(-PI * 0.4, PI * 0.4)
		var angle := dominant_angle + spread
		var dist := randf_range(min_dist, max_dist)
		var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
		_spawn_at_position(pos)

	for i in range(light_count):
		if enemy_list.size() >= MAX_ENEMIES:
			break
		var spread := randf_range(PI * 0.5, PI * 1.5)
		var angle := dominant_angle + spread
		var dist := randf_range(min_dist, max_dist)
		var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
		_spawn_at_position(pos)

func _spawn_at_position(pos: Vector2) -> void:
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
	enemy.global_position = pos
	enemy.show()
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.SetStats(get_enemy_level())
	enemy_list.append(enemy)

func _on_spawn_timer_timeout() -> void:
	var quota := get_enemy_quota()
	var current := enemy_list.size()
	if current < quota:
		_spawn_enclosing_wave(min(quota - current, 20))
	spawn_timer.wait_time = current_spawn_config["interval"]
	spawn_timer.start()

func _stress_spawn() -> void:
	for i in range(5):
		var enemy = _get_from_pool(slime_pool)
		if enemy == null:
			enemy = slime_scene.instantiate()
			enemy_holder.add_child(enemy)
			slime_pool.append(enemy)
		enemy.global_position = get_offscreen_spawn_position()
		enemy.show()
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.SetStats(get_enemy_level())
		enemy_list.append(enemy)
