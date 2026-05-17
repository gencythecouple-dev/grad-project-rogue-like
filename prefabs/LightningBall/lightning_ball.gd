extends Area2D
class_name LightningBall

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage: float = 10.0
var is_crit: bool = false
var flight_direction: Vector2 = Vector2.ZERO
var base_speed: float = 400.0
var flight_speed: float = 400.0
var bounce_count: int = 0
var max_bounces: int = 2
var enemies_hit: Array = []
var first_bounce: bool = true
var player_ref: CharacterBody2D
var ball_level: int = 1
var infinite_mode: bool = false
var infinite_timer: float = 0.0
const INFINITE_DURATION: float = 3.0
const BOUNCE_SEEK_RANGE: float = 400.0
const LIFETIME: float = 8.0
var lifetime_timer: float = 0.0
var initial_target: Area2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	sprite.play("default")
	player_ref = get_tree().get_first_node_in_group("Player")
	
	if initial_target and is_instance_valid(initial_target):
		flight_direction = global_position.direction_to(initial_target.global_position)
	else:
		flight_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	rotation = flight_direction.angle()

func _physics_process(delta: float) -> void:
	lifetime_timer += delta
	
	if infinite_mode:
		infinite_timer += delta
		if infinite_timer >= INFINITE_DURATION:
			queue_free()
			return
	elif lifetime_timer >= LIFETIME:
		queue_free()
		return
	
	global_position += flight_direction * flight_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("Enemy"):
		return
	if enemies_hit.has(area):
		return
	
	enemies_hit.append(area)
	area.TakeDamage(damage, is_crit)
	
	if player_ref:
		player_ref.total_damage_dealt += damage
	
	if ball_level >= 5 and not infinite_mode:
		infinite_mode = true
		flight_speed = base_speed * 2.0
		enemies_hit.clear()
	
	if not infinite_mode and bounce_count >= max_bounces:
		queue_free()
		return
	
	if not infinite_mode:
		bounce_count += 1
	
	var target = _get_closest_unhit_enemy()
	if target:
		flight_direction = global_position.direction_to(target.global_position)
	else:
		flight_direction = _random_direction()
	
	rotation = flight_direction.angle()

func _get_closest_unfit_enemy() -> Area2D:
	var closest_dist: float = BOUNCE_SEEK_RANGE
	var closest: Area2D = null
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemies_hit.has(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	return closest

func _get_closest_unhit_enemy() -> Area2D:
	return _get_closest_unfit_enemy()

func _random_direction() -> Vector2:
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func setup(spawn_damage: float, spawn_is_crit: bool, bounces: int, level: int) -> void:
	damage = spawn_damage
	is_crit = spawn_is_crit
	max_bounces = bounces
	ball_level = level
