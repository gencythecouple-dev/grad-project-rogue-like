extends EnemyBase

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var attack_hitbox: Area2D = $HurtBox

var knockback_decay := 10.0


const SPEED := 135
const ATTACK_RANGE := 75
const ATTACK_DAMAGE := 10.0

enum STATE { RUN, ATTACK }
var current_state: STATE = STATE.RUN

var has_hit_player := false

func _ready() -> void:
	current_scene = get_tree().get_first_node_in_group("MainScene")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	attack_cooldown.one_shot = true
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	attack_hitbox.body_entered.connect(_on_attack_hit_player)
	attack_hitbox.monitoring = false
	
	ChangeState(STATE.RUN)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
		is_stunned = true
	else:
		is_stunned = false
		knockback_velocity = Vector2.ZERO
		
		match current_state:
			STATE.RUN:
				chase_player()
				if attack_cooldown.is_stopped() and is_player_in_attack_range():
					ChangeState(STATE.ATTACK)
			STATE.ATTACK:
				velocity = Vector2.ZERO
	move_and_slide()


func apply_flash(intensity: float):
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)


func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * SPEED
	
	if dir.x != 0:
		sprite.flip_h = dir.x < 0


func ChangeState(new_state: STATE) -> void:
	current_state = new_state
	
	if new_state == STATE.RUN:
		sprite.play("run")
	elif new_state == STATE.ATTACK:
		sprite.play("attack")


func is_player_in_attack_range() -> bool:
	return global_position.distance_to(player_ref.global_position) <= ATTACK_RANGE

func SetStats(level_num):
	max_hp = base_hp * level_num
	current_hp = max_hp

func _on_attack_cooldown_timeout() -> void:
	if current_state == STATE.RUN and is_player_in_attack_range():
		ChangeState(STATE.ATTACK)

func _on_sprite_animation_finished() -> void:
	var anim_name = sprite.animation
	
	if anim_name.begins_with("attack"):
		attack_hitbox.monitoring = false
		ChangeState(STATE.RUN)
		attack_cooldown.start()

func _on_attack_hit_player(body: Node2D) -> void:
	if body.is_in_group("Player") and not has_hit_player:
		has_hit_player = true
		if body.has_method("TakeDamage"):
			body.TakeDamage(ATTACK_DAMAGE)

func enable_attack_hitbox():
	attack_hitbox.monitoring = true

func disable_attack_hitbox():
	attack_hitbox.monitoring = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		disable_attack_hitbox()
		ChangeState(STATE.RUN)
		attack_cooldown.start()


func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation.begins_with("attack") and sprite.frame == 5:
		enable_attack_hitbox()
