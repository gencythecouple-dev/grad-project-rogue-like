extends CharacterBody2D

var SPEED := 250

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $ProgressBar

@export var arrow_scene: PackedScene
@export var hammer_scene: PackedScene

var target: CharacterBody2D
var current_scene: Node2D
var player_ui  
var level_up_menu

var active_weapons: Array = []
var passive_buffs: Array = []

var direction := Vector2.ZERO
var facing_right := true
var attacking := false
var last_direction := Vector2.RIGHT

var base_attack: float = 3.0
var current_attack: float
var base_armor: float = 5.0
var current_armor: float
var base_hp := 200
var max_hp: int
var current_hp: int

var projectile_count: int = 1
var hammer_scale: float = 1.0
var hammer_level: int = 0


var current_exp: int = 0
var exp_to_next_level: int = 10
var player_level: int = 1

var total_damage_dealt: float = 0.0
var total_kills: int = 0
var total_exp_collected: int = 0



func _ready() -> void:
	SetStats()
	add_to_group("Player")
	
	if arrow_scene:
		active_weapons.append(arrow_scene)
	
	current_scene = get_tree().root.get_child(0)
	
	player_ui = get_tree().get_first_node_in_group("PlayerUI")
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
		player_ui.update_level(player_level)
	
	if current_scene:
		level_up_menu = current_scene.get_node_or_null("LevelUpMenu")
		if level_up_menu:
			level_up_menu.upgrade_selected.connect(_on_upgrade_selected)
	
	attack_timer.one_shot = true
	attack_timer.start()

func _physics_process(delta: float) -> void:
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = direction
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

func _get_closest_enemy() -> CharacterBody2D:
	var closest_distance: float = INF
	var target_enemy: CharacterBody2D = null
	for enemy in current_scene.enemy_list:
		if enemy == null or !is_instance_valid(enemy):
			continue
		var dist: float = enemy.global_position.distance_to(global_position)
		if dist < closest_distance:
			closest_distance = dist
			target_enemy = enemy
	return target_enemy

func _equip_weapon(weapon_scene: PackedScene, icon: Texture2D) -> void:
	if active_weapons.size() >= 3:
		return
	active_weapons.append(weapon_scene)
	if player_ui:
		player_ui.add_active_item(icon)

func _equip_passive(buff: String, icon: Texture2D) -> void:
	if passive_buffs.size() >= 3:
		return
	passive_buffs.append(buff)
	if player_ui:
		player_ui.add_passive_item(icon)

func start_attack() -> void:
	if attacking or not has_valid_enemy():
		return
	attacking = true
	sprite.play("attack")

func Attack() -> void:
	var target_enemy: CharacterBody2D = _get_closest_enemy()
	if target_enemy == null:
		return

	for weapon in active_weapons:
		if weapon == hammer_scene:
			_spawn_hammer()
		elif weapon == arrow_scene:
			_spawn_arrows(target_enemy)


func _spawn_hammer() -> void:
	if hammer_scene == null:
		return
	var hammer = hammer_scene.instantiate()
	add_child(hammer)
	hammer.position = Vector2(80 if facing_right else -80, 0)
	hammer.setup(self, current_attack, hammer_level, hammer_scale)

func _spawn_arrows(target_enemy: CharacterBody2D) -> void:
	var target_position = target_enemy.global_position
	var angle_spread = 15
	var start_angle = -(projectile_count - 1) * angle_spread / 2.0
	for i in range(projectile_count):
		var delay = i * 0.1
		var current_angle = start_angle + (i * angle_spread)
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_arrow_at_position(target_position, current_angle)
		)

func _spawn_arrow_at_position(target_pos: Vector2, angle_offset: float) -> void:
	if arrow_scene == null:
		return
	var new_arrow: Arrow = arrow_scene.instantiate()
	new_arrow.global_position = global_position
	new_arrow.damage = current_attack
	var dir = global_position.direction_to(target_pos)
	dir = dir.rotated(deg_to_rad(angle_offset))
	new_arrow.set_meta("direction", dir)
	current_scene.arrow_holder.add_child(new_arrow)

func end_attack() -> void:
	attacking = false
	attack_timer.start()

func SetStats() -> void:
	current_attack = base_attack
	current_armor = base_armor
	max_hp = base_hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func CollectExperience(amount: int) -> void:
	current_exp += amount
	total_exp_collected += amount
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
	while current_exp >= exp_to_next_level:
		level_up()

func _calculate_exp_to_next_level(level: int) -> int:
	if level == 1:
		return 5
	elif level <= 30:
		return 5 + (level - 1) * 10
	elif level <= 55:
		return 5 + (29 * 10) + (level - 30) * 13
	else:
		return 5 + (29 * 10) + (25 * 13) + (level - 55) * 16




func level_up() -> void:
	player_level += 1
	current_exp -= exp_to_next_level
	exp_to_next_level = _calculate_exp_to_next_level(player_level)
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
		player_ui.update_level(player_level)
	if level_up_menu:
		level_up_menu.show_upgrades()
	else:
		current_attack += 1.0
		max_hp += 10
		health_bar.max_value = max_hp
		health_bar.value = current_hp

func _on_upgrade_selected(upgrade_stat: String) -> void:
	match upgrade_stat:
		"ice_hammer":
			hammer_level += 1
			if hammer_level == 1:
				_equip_weapon(hammer_scene, preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
			match hammer_level:
				2: current_attack += 2.0
				3: hammer_scale += 0.3
				4: attack_timer.wait_time *= 0.80
				5:
					current_attack += 2.0
					attack_timer.wait_time *= 0.80
					hammer_scale += 0.3
		"arrow":
			_equip_weapon(arrow_scene, preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"attack":
			current_attack += 1.0
			_equip_passive("attack", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"attack_big":
			current_attack += 2.0
			_equip_passive("attack_big", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"attack_speed":
			attack_timer.wait_time *= 0.85
			_equip_passive("attack_speed", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"move_speed":
			SPEED *= 1.15
			_equip_passive("move_speed", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"max_hp":
			max_hp += 10
			current_hp += 10
			health_bar.max_value = max_hp
			health_bar.value = current_hp
			_equip_passive("max_hp", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"max_hp_big":
			max_hp += 20
			current_hp = max_hp
			health_bar.max_value = max_hp
			health_bar.value = current_hp
			_equip_passive("max_hp_big", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"more_projectile":
			projectile_count += 1
			_equip_passive("more_projectile", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
		"armor":
			current_armor += 1.0
			_equip_passive("armor", preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))


func TakeDamage(damage: float) -> void:
	var actual_damage = max(0.05, damage - current_armor)
	current_hp -= damage
	current_hp = max(0, current_hp)
	health_bar.value = current_hp
	if current_hp <= 0:
		Die()

func Die() -> void:
	var level = get_tree().root.get_child(0)
	level.show_game_over(self)

func _on_attack_timer_timeout() -> void:
	start_attack()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		end_attack()

func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack" and sprite.frame == 5:
		Attack()
