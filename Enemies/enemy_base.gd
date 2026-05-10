extends CharacterBody2D
class_name EnemyBase

@export var exp_value: int = 5
@export var base_hp: int = 3
@export var speed: float = 80.0
@export var damage_number_scene: PackedScene

const ATTACK_DAMAGE: float = 8.0
const KNOCKBACK_STRENGTH: float = 300.0
const KNOCKBACK_DECAY: float = 10.0
const FLASH_DURATION: float = 0.1
const CULL_DISTANCE: float = 1000.0
const SEPARATION_RADIUS: float = 32.0
const SEPARATION_STRENGTH: float = 200.0

var knockback_velocity := Vector2.ZERO
var current_scene
var player_ref
var max_hp: int
var current_hp: int
var flash_timer: float = 0.0
var is_dying: bool = false
var tick_offset: int

func _ready() -> void:
	add_to_group("Enemy")
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	setup_enemy()
	tick_offset = randi() % 4

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	if global_position.distance_to(player_ref.global_position) > CULL_DISTANCE:
		return

	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)

	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		move_and_slide()
		return

	# Chase player
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * speed

	# Flip sprite
	if has_node("AnimatedSprite2D") and dir.x != 0:
		get_node("AnimatedSprite2D").flip_h = dir.x < 0

	# Separation - staggered per enemy
	if Engine.get_physics_frames() % 4 == tick_offset:
		var separation := Vector2.ZERO
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if enemy == self or not is_instance_valid(enemy):
				continue
			var diff: Vector2 = global_position - enemy.global_position
			var dist := diff.length()
			if dist > 0 and dist < SEPARATION_RADIUS:
				separation += diff.normalized() * (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS * SEPARATION_STRENGTH
		velocity += separation

	move_and_slide()

	# Damage player on contact
	if global_position.distance_to(player_ref.global_position) < 32:
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

	enemy_behavior(delta)

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
	spawn_damage_number(damage, is_crit)

	if player_ref:
		var knockback_dir: Vector2 = (global_position - player_ref.global_position).normalized()
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
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos := global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos, is_crit)
