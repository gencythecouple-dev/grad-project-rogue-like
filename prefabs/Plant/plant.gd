extends EnemyBase

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

const SPEED := 60
var is_touching_player := false

func _ready() -> void:
	super._ready()
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	sprite.play("default")
	
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	
	chase_player()
	move_and_slide()
	
	if is_touching_player:
		player_ref.TakeDamage(ATTACK_DAMAGE * delta)

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	dir = dir.normalized()
	velocity = dir * SPEED
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0

func apply_flash(intensity: float):
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)

func _on_attack_area_entered(body):
	if body.is_in_group("Player"):
		is_touching_player = true

func _on_attack_area_exited(body):
	if body.is_in_group("Player"):
		is_touching_player = false
