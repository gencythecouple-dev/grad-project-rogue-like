extends EnemyBase

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 135
const ATTACK_DAMAGE: float = 0.5
const ATTACK_RANGE := 30


func _ready() -> void:
	super._ready()
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	sprite.play("run")
	

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	chase_player()
	move_and_slide()
	print("dist: ", global_position.distance_to(player_ref.global_position), " range: ", ATTACK_RANGE)
	if is_player_in_attack_range():
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	dir = dir.normalized()
	velocity = dir * SPEED
	if dir.x != 0:
		sprite.flip_h = dir.x < 0

func is_player_in_attack_range() -> bool:
	return global_position.distance_to(player_ref.global_position) <= ATTACK_RANGE

func apply_flash(intensity: float):
	print("flash intensity: ", intensity)
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)
