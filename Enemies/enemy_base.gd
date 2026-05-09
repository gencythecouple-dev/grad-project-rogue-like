extends CharacterBody2D
class_name EnemyBase

@export var exp_value: int = 5
@export var base_hp: int = 3
@export var speed: float = 80
@export var damage_number_scene: PackedScene


# Common variables
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
var separation_force: float = 100.0


# Constants
const KNOCKBACK_STRENGTH := 300.0
const KNOCKBACK_DECAY := 10.0
const FLASH_DURATION := 0.1

func _ready() -> void:
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	setup_enemy()

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
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
	
	apply_soft_collision(delta)
	global_position += velocity * delta


func apply_soft_collision(delta: float):
	var push = Vector2.ZERO
	var nearby = get_tree().get_nodes_in_group("Enemy")
	
	for other in nearby:
		if other == self or other == null:
			continue
		
		var distance = global_position.distance_to(other.global_position)
		if distance < 40 and distance > 0:
			var direction = (global_position - other.global_position).normalized()
			push += direction * (40 - distance) * separation_force
	
	global_position += push * delta

func setup_enemy():
	pass

func enemy_behavior(delta: float):
	pass

func apply_flash(intensity: float):
	pass

func SetStats(level_num: int):
	max_hp = base_hp * level_num
	current_hp = max_hp
	
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

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * speed
