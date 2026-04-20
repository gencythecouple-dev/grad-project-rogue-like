extends EnemyBase

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 135
const ATTACK_DAMAGE: float = 1
const ATTACK_RANGE := 75
var base_hp := 8
var exp_value := 3


func _ready() -> void:
	super._ready()
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	sprite.play("run")

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	chase_player()
	move_and_slide()

	if is_player_in_attack_range():
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * SPEED
	if dir.x != 0:
		sprite.flip_h = dir.x < 0

func is_player_in_attack_range() -> bool:
	return global_position.distance_to(player_ref.global_position) <= ATTACK_RANGE

func apply_flash(intensity: float):
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)
