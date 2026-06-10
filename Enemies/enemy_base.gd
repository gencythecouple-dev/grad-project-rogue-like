extends Area2D
class_name EnemyBase

@export var exp_value: int = 5
@export var base_hp: int = 3
@export var speed: float = 80.0
@export var damage_number_scene: PackedScene

const ATTACK_DAMAGE: float = 8.0
const KNOCKBACK_STRENGTH: float = 300.0
const KNOCKBACK_DECAY: float = 10.0
const FLASH_DURATION: float = 0.1
const SEPARATION_RADIUS: float = 40.0
const SEPARATION_STRENGTH: float = 600.0
const PLAYER_SEPARATION_STRENGTH: float = 1000.0
const TARGET_WEIGHT: float = 10.0
const SKIP_FRAMES: int = 20
const MAX_QUERY_RESULTS: int = 8
const JITTER_FIX: float = 0.5

var velocity := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var current_scene
var player_ref: CharacterBody2D
var max_hp: int
var current_hp: int
var flash_timer: float = 0.0
var is_dying: bool = false
var tick_offset: int
var query: PhysicsShapeQueryParameters2D
var cached_neighbors: Array[Vector2] = []
var cached_sprite: AnimatedSprite2D = null

func _ready() -> void:
	add_to_group("Enemy")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	setup_enemy()
	tick_offset = randi() % (SKIP_FRAMES + 1)
	if has_node("AnimatedSprite2D"):
		cached_sprite = get_node("AnimatedSprite2D")
	var circle := CircleShape2D.new()
	circle.radius = SEPARATION_RADIUS
	query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_bodies = false
	query.collide_with_areas = true
	query.collision_mask = 2
	query.shape = circle
	query.exclude = [get_rid()]
	query.transform = Transform2D.IDENTITY

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	if knockback_velocity.length() > 10:
		position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		return

	var target_dir: Vector2 = current_scene.flow_field.get_direction(position)
	if target_dir == Vector2.ZERO:
		target_dir = (player_ref.position - position).normalized()

	var move_dir: Vector2 = target_dir

	var obstacles := get_tree().get_nodes_in_group("Obstacle")
	for obstacle in obstacles:
		var diff: Vector2 = position - obstacle.global_position
		var dist: float = diff.length()
		var push_radius: float = SEPARATION_RADIUS * 1.2
		if dist < push_radius and dist > 0:
			var push_normal: Vector2 = diff / dist
			var overlap: float = push_radius - dist
			position += push_normal * overlap * 0.9
			var into_obstacle: float = move_dir.dot(-push_normal)
			if into_obstacle > 0:
				move_dir += push_normal * into_obstacle

	move_dir = move_dir.normalized() if move_dir.length() > 0.01 else Vector2.ZERO
	velocity = move_dir * speed

	if cached_sprite and move_dir.x != 0:
		cached_sprite.flip_h = move_dir.x < 0

	if (Engine.get_physics_frames() + tick_offset) % (SKIP_FRAMES + 1) == 0:
		query.transform.origin = position
		var results = get_world_2d().direct_space_state.intersect_shape(query, MAX_QUERY_RESULTS)
		cached_neighbors.clear()
		for result in results:
			cached_neighbors.append(result.collider.position)
		_separate_from(player_ref.position, PLAYER_SEPARATION_STRENGTH)

	for other_pos in cached_neighbors:
		var diff: Vector2 = position - other_pos
		var dist: float = diff.length()
		if dist < SEPARATION_RADIUS and dist > 0:
			position += (diff / dist) * (SEPARATION_RADIUS - dist) * 0.5

	var player_dist: float = position.distance_to(player_ref.position)
	if player_dist < SEPARATION_RADIUS and player_dist > 0:
		var push: Vector2 = position - player_ref.position
		position += push.normalized() * (SEPARATION_RADIUS - player_dist) * 0.5

	position += velocity * delta

	if position.distance_to(player_ref.position) < SEPARATION_RADIUS + 5.0:
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

	enemy_behavior(delta)

func _separate_from(other_pos: Vector2, weight: float) -> void:
	var vec: Vector2 = position - other_pos
	if vec.is_zero_approx():
		return
	velocity += vec.normalized() * 1.0 / vec.length() * weight

func enemy_behavior(delta: float) -> void:
	pass

func setup_enemy() -> void:
	pass

func apply_flash(intensity: float) -> void:
	pass

func SetStats(level_num: int) -> void:
	max_hp = base_hp * level_num
	current_hp = max_hp

func TakeDamage(damage: float, is_crit: bool = false) -> void:
	if is_dying:
		return
	current_hp -= damage
	flash_timer = FLASH_DURATION
	AudioManager.play_hit()
	spawn_damage_number(damage, is_crit)
	if player_ref:
		var knockback_dir: Vector2 = (position - player_ref.position).normalized()
		knockback_velocity = knockback_dir * KNOCKBACK_STRENGTH
	if current_hp <= 0:
		is_dying = true
		await get_tree().create_timer(FLASH_DURATION).timeout
		on_death()

func on_death() -> void:
	current_scene.enemy_died.emit(self)
	current_scene.return_to_pool(self)

func spawn_damage_number(damage: float, is_crit: bool = false) -> void:
	if damage_number_scene == null:
		return
	if not GameData.show_damage_numbers:
		return
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos: Vector2 = position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos, is_crit)
