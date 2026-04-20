extends CharacterBody2D
class_name EnemyBase

@export var exp_value: int = 5
@export var base_hp: int = 3
@export var speed: float = 150.0
@export var damage_number_scene: PackedScene

# Common variables
var knockback_velocity := Vector2.ZERO
var is_stunned := false
var current_scene
var player_ref
var max_hp: int
var current_hp: int
var flash_timer := 0.0

# Constants
const KNOCKBACK_STRENGTH := 300.0
const KNOCKBACK_DECAY := 10.0
const FLASH_DURATION := 0.15

func _ready() -> void:
	current_scene = get_tree().root.get_child(0)
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	setup_enemy()

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	
	# Handle knockback
	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		is_stunned = true
	else:
		is_stunned = false
		knockback_velocity = Vector2.ZERO
		
		if not is_stunned:
			enemy_behavior(delta)
	
	move_and_slide()

func setup_enemy():
	pass

func enemy_behavior(delta: float):
	pass

func apply_flash(intensity: float):
	pass

func SetStats(level_num: int):
	max_hp = base_hp * level_num
	current_hp = max_hp
	
func TakeDamage(damage: float) -> void:
	_on_hurt(damage)

func _on_hurt(damage: float):
	current_hp -= damage
	flash_timer = FLASH_DURATION
	spawn_damage_number(damage)
	
	if player_ref:
		var knockback_dir = (global_position - player_ref.global_position).normalized()
		knockback_velocity = knockback_dir * KNOCKBACK_STRENGTH
	
	if current_hp <= 0:
		on_death()

func on_death() -> void:
	current_scene.enemy_died.emit(self)
	current_scene.return_to_pool(self)

func spawn_damage_number(damage: float):
	if damage_number_scene == null:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos)

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * speed
