extends CharacterBody2D

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var attack_hitbox: Area2D = $HurtBox
@onready var run_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Run.png")
@onready var attack_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Attack1.png")

@export var damage_number_scene: PackedScene  # Assign DamageNumber.tscn here

var knockback_velocity := Vector2.ZERO
var knockback_decay := 10.0
var is_stunned := false

const SPEED := 150
const ATTACK_RANGE := 75
const KNOCKBACK_STRENGTH := 300.0
const ATTACK_DAMAGE := 10.0
const FLASH_DURATION := 0.15  # How long the flash lasts

var current_scene
var player_ref

enum STATE { RUN, ATTACK }
var current_state: STATE = STATE.RUN

var base_hp := 3
var max_hp : int
var current_hp : int
var has_hit_player := false
var flash_timer := 0.0

func _ready() -> void:
	current_scene = get_tree().get_first_node_in_group("MainScene")
	player_ref = get_tree().get_first_node_in_group("Player")
	SetStats(1)
	attack_cooldown.one_shot = true
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	
	attack_hitbox.monitoring = false
	attack_hitbox.body_entered.connect(_on_attack_hit_player)
	
	ChangeState(STATE.RUN)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return
	
	# Handle flash effect
	if flash_timer > 0:
		flash_timer -= delta
		var material = sprite.material as ShaderMaterial
		if material:
			material.set_shader_parameter("flash_intensity", flash_timer / FLASH_DURATION)
	
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

func chase_player():
	var dir := global_position.direction_to(player_ref.global_position)
	velocity = dir * SPEED
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func ChangeState(new_state: STATE) -> void:
	current_state = new_state
	if new_state == STATE.RUN:
		sprite.texture = run_sheet
		anim_player.play("run")
		attack_hitbox.monitoring = false
	elif new_state == STATE.ATTACK:
		sprite.texture = attack_sheet
		anim_player.play("attack")
		attack_cooldown.start()
		has_hit_player = false

func is_player_in_attack_range() -> bool:
	return global_position.distance_to(player_ref.global_position) <= ATTACK_RANGE

func SetStats(level_num):
	max_hp = base_hp * level_num
	current_hp = max_hp

func _on_attack_cooldown_timeout() -> void:
	if current_state == STATE.RUN and is_player_in_attack_range():
		ChangeState(STATE.ATTACK)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		attack_hitbox.monitoring = false
		ChangeState(STATE.RUN)
		attack_cooldown.start()

func _on_hurt(damage: float):
	print("Enemy _on_hurt called! Damage: ", damage, " Current HP: ", current_hp)
	current_hp -= damage
	
	# Trigger flash effect
	flash_timer = FLASH_DURATION
	
	# Spawn damage number
	spawn_damage_number(damage)
	
	if player_ref:
		var knockback_dir = (global_position - player_ref.global_position).normalized()
		knockback_velocity = knockback_dir * KNOCKBACK_STRENGTH
	
	print("After damage HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		print("Enemy died!")
		current_scene.enemy_died.emit(self)
		queue_free()

func spawn_damage_number(damage: float):
	if damage_number_scene == null:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	# Spawn slightly above the enemy
	var spawn_pos = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos)

func _on_attack_hit_player(body: Node2D) -> void:
	if body.is_in_group("Player") and not has_hit_player:
		has_hit_player = true
		if body.has_method("TakeDamage"):
			body.TakeDamage(ATTACK_DAMAGE)
			print("Swordman dealt ", ATTACK_DAMAGE, " damage to player!")

func enable_attack_hitbox():
	attack_hitbox.monitoring = true

func disable_attack_hitbox():
	attack_hitbox.monitoring = false
