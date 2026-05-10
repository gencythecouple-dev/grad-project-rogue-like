extends CharacterBody2D
class_name EnemyBase

@export var exp_value: int = 5
@export var base_hp: int = 3
@export var speed: float = 80
@export var damage_number_scene: PackedScene


const ATTACK_DAMAGE: float = 1.0
const SEPARATION_DISTANCE: float = 40.0
const SEPARATION_STRENGTH: float = 150.0

var knockback_velocity := Vector2.ZERO
var is_stunned := false
var current_scene
var player_ref
var max_hp: int
var current_hp: int
var flash_timer := 0.0
var is_dying := false
var update_offset: float = 0.0
var update_interval: float = 0.1
var separation_area: Area2D

const KNOCKBACK_STRENGTH := 300.0
const KNOCKBACK_DECAY := 10.0
const FLASH_DURATION := 0.1

func _ready() -> void:
	add_to_group("Enemy")
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	setup_enemy()
	update_offset = randf() * update_interval
	
	separation_area = Area2D.new()
	add_child(separation_area)
	var shape = CircleShape2D.new()
	shape.radius = SEPARATION_DISTANCE
	var collision = CollisionShape2D.new()
	collision.shape = shape
	separation_area.add_child(collision)
	separation_area.collision_layer = 0
	separation_area.collision_mask = 2

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	
	if knockback_velocity.length() > 10:
		global_position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		is_stunned = true
	else:
		is_stunned = false
		knockback_velocity = Vector2.ZERO
		
		if not is_stunned:
			update_offset += delta
			if update_offset >= update_interval:
				update_offset = 0.0
				enemy_behavior(delta)
	
	apply_soft_separation()
	global_position += velocity * delta
	
	check_player_collision(delta)

func enemy_behavior(delta: float):
	chase_player()

func apply_soft_separation():
	var separation = Vector2.ZERO
	var nearby = separation_area.get_overlapping_bodies()
	
	for other in nearby:
		if other == self:
			continue
		
		var distance = global_position.distance_to(other.global_position)
		if distance > 0:
			var push_direction = (global_position - other.global_position).normalized()
			var push_strength = (SEPARATION_DISTANCE - distance) / SEPARATION_DISTANCE
			separation += push_direction * push_strength * SEPARATION_STRENGTH
	
	velocity += separation * get_physics_process_delta_time()

func check_player_collision(delta: float):
	if global_position.distance_to(player_ref.global_position) < 30:
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

func setup_enemy():
	pass

func apply_flash(intensity: float):
	pass

func SetStats(level_num: int):
	max_hp = base_hp * level_num
	current_hp = max_hp

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * speed
	
	if has_node("AnimatedSprite2D"):
		var sprite = get_node("AnimatedSprite2D")
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

func TakeDamage(damage: float, is_crit: bool = false) -> void:
	if is_dying:
		return
	
	current_hp -= damage
	flash_timer = FLASH_DURATION
	spawn_damage_number(damage, is_crit)
	
	if player_ref:
		var knockback_dir = (global_position - player_ref.global_position).normalized()
		knockback_velocity = knockback_dir * KNOCKBACK_STRENGTH
	
	if current_hp <= 0:
		is_dying = true
		await get_tree().create_timer(FLASH_DURATION).timeout
		on_death()

func on_death() -> void:
	current_scene.enemy_died.emit(self)
	current_scene.return_to_pool(self)

func spawn_damage_number(damage: float, is_crit: bool = false):
	if damage_number_scene == null:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos, is_crit)
