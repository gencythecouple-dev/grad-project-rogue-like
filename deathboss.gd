extends Area2D
class_name DeathBoss

const SPEED: float = 500.0
const KNOCKBACK_RESISTANCE: float = 0.99
const KILL_DISTANCE: float = 32.0
const KNOCKBACK_DECAY: float = 10.0

var player_ref: CharacterBody2D
var current_scene: Node
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("Enemy")
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	player_ref = get_tree().get_first_node_in_group("Player")
	current_scene = get_tree().root.get_node("Level")
	$AnimatedSprite2D.play("default")

func _physics_process(delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return

	if knockback_velocity.length() > 10:
		position += knockback_velocity * (1.0 - KNOCKBACK_RESISTANCE) * delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	var dir := (player_ref.global_position - global_position).normalized()
	position += dir * SPEED * delta

	if dir.x != 0:
		$AnimatedSprite2D.flip_h = dir.x < 0

	if global_position.distance_to(player_ref.global_position) < KILL_DISTANCE:
		player_ref.Die()

func TakeDamage(_damage: float, _is_crit: bool = false) -> void:
	if player_ref:
		var knockback_dir := (global_position - player_ref.global_position).normalized()
		knockback_velocity = knockback_dir * 300.0
