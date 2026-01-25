extends CharacterBody2D

const SPEED := 250

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $ProgressBar

@export var arrow_scene: PackedScene

var current_scene: Node2D
var player_ui  # PlayerUI reference

var direction := Vector2.ZERO
var facing_right := true
var attacking := false

# Combat stats
var base_attack: float = 3.0
var current_attack: float

var base_hp := 50
var max_hp: int
var current_hp: int

# Experience variables
var current_exp: int = 0
var exp_to_next_level: int = 10
var player_level: int = 1

func _ready() -> void:
	SetStats()
	add_to_group("Player")
	current_scene = get_tree().get_first_node_in_group("MainScene")
	
	# Get PlayerUI reference
	player_ui = get_tree().get_first_node_in_group("PlayerUI")
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
		player_ui.update_level(player_level)
	else:
		print("Warning: PlayerUI not found!")
	
	attack_timer.one_shot = true
	attack_timer.start()

func _physics_process(delta: float) -> void:
	# Get input direction
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	# Calculate velocity
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	update_facing()
	move_and_slide()
	update_animation()

func update_facing() -> void:
	if direction.x != 0:
		facing_right = direction.x > 0
	sprite.flip_h = !facing_right

func update_animation() -> void:
	if attacking:
		return
	
	if direction == Vector2.ZERO:
		if sprite.animation != "idle":
			sprite.play("idle")
	else:
		if sprite.animation != "run":
			sprite.play("run")

func has_valid_enemy() -> bool:
	if current_scene == null:
		return false
	
	for enemy in current_scene.enemy_list:
		if enemy != null and is_instance_valid(enemy):
			return true
	
	return false

func start_attack() -> void:
	if attacking or not has_valid_enemy():
		return
	
	attacking = true
	sprite.play("attack")

func Attack() -> void:
	if arrow_scene == null:
		return
	
	var new_arrow: Arrow = arrow_scene.instantiate()
	var closest_distance: float = INF
	var target_enemy: CharacterBody2D = null
	
	# Find closest enemy
	for enemy in current_scene.enemy_list:
		if enemy == null or !is_instance_valid(enemy):
			continue
		
		var dist: float = enemy.global_position.distance_to(global_position)
		if dist < closest_distance:
			closest_distance = dist
			target_enemy = enemy
	
	if target_enemy == null:
		new_arrow.queue_free()
		return
	
	# Setup and spawn arrow
	new_arrow.target = target_enemy
	new_arrow.global_position = global_position
	new_arrow.damage = current_attack
	current_scene.arrow_holder.add_child(new_arrow)

func end_attack() -> void:
	attacking = false
	attack_timer.start()

func SetStats() -> void:
	current_attack = base_attack
	max_hp = base_hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func CollectExperience(amount: int) -> void:
	current_exp += amount
	
	# Update UI
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
	
	print("💎 Collected ", amount, " exp. Total: ", current_exp, "/", exp_to_next_level)
	
	# Check for level up
	while current_exp >= exp_to_next_level:
		level_up()

func level_up() -> void:
	player_level += 1
	current_exp -= exp_to_next_level
	exp_to_next_level = int(exp_to_next_level * 1.5)
	
	# Update UI
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
		player_ui.update_level(player_level)
	
	print("⭐ LEVEL UP! Now level ", player_level)
	
	# Increase stats on level up
	current_attack += 1.0
	max_hp += 10
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func TakeDamage(damage: float) -> void:
	current_hp -= damage
	current_hp = max(0, current_hp)
	health_bar.value = current_hp
	
	print("Player HP: ", current_hp, "/", max_hp)
	
	if current_hp <= 0:
		Die()

func Die() -> void:
	print("💀 Player died!")
	get_tree().reload_current_scene()

# Signal callbacks
func _on_attack_timer_timeout() -> void:
	start_attack()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		end_attack()

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack" and sprite.frame == 5:
		Attack()
