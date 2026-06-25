extends CharacterBody2D

var SPEED: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $ProgressBar
@export var hammer_scene: PackedScene
@export var magic_bullet_scene: PackedScene
@export var knife_scene: PackedScene
@export var holy_smite_scene: PackedScene
@export var sword_scene: PackedScene
@export var sword_aura_scene: PackedScene
@export var wind_shuriken_scene: PackedScene
@export var star_projectile_scene: PackedScene
@export var level_up_effect_scene: PackedScene
@export var lightning_ball_scene: PackedScene

var flash_timer: float = 0.0
const FLASH_DURATION: float = 0.1
var target: Area2D
var current_scene: Node
var player_ui
var level_up_menu
var rainbow_active: bool = false
var rainbow_timer: float = 0.0

var active_weapons: Array = []
var passive_buffs: Array = []

var direction := Vector2.ZERO
var facing_right := true
var last_direction := Vector2.RIGHT

var base_attack: float = 3.0
var current_attack: float
var base_armor: float = 5.0
var current_armor: float
var base_hp := 200
var max_hp: int
var current_hp: int

var global_projectile_bonus: int = 0
var attack_speed_multiplier: float = 1.0

# Weapon levels
var hammer_level: int = 0
var magic_bullet_level: int = 0
var knife_level: int = 0
var holy_smite_level: int = 0
var sword_level: int = 0
var wind_shuriken_level: int = 0
var star_level: int = 0
var lightning_ball_level: int = 0

# Weapon stats
var magic_bullet_projectile_count: int = 1
var magic_bullet_pierce: int = 0
var knife_projectile_count: int = 1
var holy_smite_count: int = 1
var holy_smite_aoe: float = 1.0
var wind_shuriken_count: int = 1
var star_count: int = 1
var star_speed: float = 300.0
var hammer_scale: float = 1.0
var sword_aura_instance = null

# Individual weapon timers (start at 0 = fires immediately on pickup)
var hammer_timer: float = 0.0
var hammer_cooldown: float = 2.25
var magic_bullet_timer: float = 0.0
var magic_bullet_cooldown: float = 3.25
var knife_timer: float = 0.0
var knife_cooldown: float = 2.75
var holy_smite_timer: float = 0.0
var holy_smite_cooldown: float = 3.5
var sword_timer: float = 0.0
var sword_cooldown: float = 1.95
var wind_shuriken_timer: float = 0.0
var wind_shuriken_cooldown: float = 3.25
var star_timer: float = 0.0
var star_cooldown: float = 5.75
var lightning_ball_timer: float = 0.0
var lightning_ball_cooldown: float = 4.25

# Player exp and level
var current_exp: int = 0
var exp_to_next_level: int = 15
var player_level: int = 1

# End game summary
var total_damage_dealt: float = 0.0
var total_kills: int = 0
var total_exp_collected: int = 0
var run_gold: int = 0

# Passives
var magnet_range: float = 50.0
var exp_multiplier: float = 1.0
var crit_chance: float = 0.0
var vampirism: int = 0
var might_multiplier: float = 1.0
var revivals_remaining: int = 0
var recovery_rate: float = 0.0
var recovery_timer: float = 0.0


func _ready() -> void:
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	SetStats()
	_apply_meta_upgrades()
	add_to_group("Player")
	current_scene = get_tree().root.get_node("Level")
	player_ui = get_tree().get_first_node_in_group("PlayerUI")
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
		player_ui.update_level(player_level)
	if current_scene:
		level_up_menu = current_scene.get_node_or_null("LevelUpMenu")
		if level_up_menu:
			level_up_menu.upgrade_selected.connect(_on_upgrade_selected)
	match GameData.selected_weapon:
		"magic_bullet":
			if magic_bullet_scene:
				magic_bullet_level = 1
				_equip_weapon(magic_bullet_scene, preload("res://Assets/magic_bullet.png"))
				if level_up_menu:
					level_up_menu.upgrade_levels["magic_bullet"] = 1
		"knife":
			if knife_scene:
				knife_level = 1
				_equip_weapon(knife_scene, preload("res://Assets/knife_icon.png"))
				if level_up_menu:
					level_up_menu.upgrade_levels["knife"] = 1
		"ice_hammer":
			if hammer_scene:
				hammer_level = 1
				_equip_weapon(hammer_scene, preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"))
				if level_up_menu:
					level_up_menu.upgrade_levels["ice_hammer"] = 1
		"sword":
			if sword_scene:
				sword_level = 1
				_equip_weapon(sword_scene, preload("res://Assets/Sword/sword.png"))
				if level_up_menu:
					level_up_menu.upgrade_levels["sword"] = 1


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
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	if rainbow_active:
		rainbow_timer += delta
		var mat = sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("rgb_cycle", fmod(rainbow_timer * 0.5, 1.0))
			mat.set_shader_parameter("rainbow_active", true)
	update_animation()
	update_facing()
	move_and_slide()
	_tick_weapons(delta)
	_tick_recovery(delta)


func _tick_weapons(delta: float) -> void:
	var target_enemy = _get_closest_enemy()

	if hammer_level > 0:
		hammer_timer -= delta
		if hammer_timer <= 0:
			_spawn_hammer()
			hammer_timer = hammer_cooldown * attack_speed_multiplier

	if magic_bullet_level > 0:
		magic_bullet_timer -= delta
		if magic_bullet_timer <= 0:
			if target_enemy:
				_spawn_magic_bullets(target_enemy)
			magic_bullet_timer = magic_bullet_cooldown * attack_speed_multiplier

	if knife_level > 0:
		knife_timer -= delta
		if knife_timer <= 0:
			_spawn_knives()
			knife_timer = knife_cooldown * attack_speed_multiplier

	if holy_smite_level > 0:
		holy_smite_timer -= delta
		if holy_smite_timer <= 0:
			_spawn_holy_smites()
			holy_smite_timer = holy_smite_cooldown * attack_speed_multiplier

	if sword_level > 0:
		sword_timer -= delta
		if sword_timer <= 0:
			_spawn_sword()
			sword_timer = sword_cooldown * attack_speed_multiplier

	if wind_shuriken_level > 0:
		wind_shuriken_timer -= delta
		if wind_shuriken_timer <= 0:
			_spawn_wind_shurikens()
			wind_shuriken_timer = wind_shuriken_cooldown * attack_speed_multiplier

	if star_level > 0:
		star_timer -= delta
		if star_timer <= 0:
			_spawn_stars()
			star_timer = star_cooldown * attack_speed_multiplier

	if lightning_ball_level > 0:
		lightning_ball_timer -= delta
		if lightning_ball_timer <= 0:
			_spawn_lightning_ball()
			lightning_ball_timer = lightning_ball_cooldown * attack_speed_multiplier


func apply_flash(intensity: float) -> void:
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)

func update_facing() -> void:
	if direction.x != 0:
		facing_right = direction.x > 0
	sprite.flip_h = !facing_right

func update_animation() -> void:
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

func _get_closest_enemy() -> Node2D:
	var closest_distance: float = INF
	var target_enemy: Node2D = null
	for enemy in current_scene.enemy_list:
		if enemy == null or !is_instance_valid(enemy):
			continue
		if not enemy.is_in_group("Enemy") and not enemy.is_in_group("Boss"):
			continue
		var dist: float = enemy.global_position.distance_to(global_position)
		if dist < closest_distance:
			closest_distance = dist
			target_enemy = enemy
	return target_enemy

func _equip_weapon(weapon_scene: PackedScene, icon: Texture2D) -> void:
	if active_weapons.size() >= 4:
		return
	active_weapons.append(weapon_scene)
	if player_ui:
		player_ui.add_active_item(icon)

func _equip_passive(buff: String, icon: Texture2D) -> void:
	if passive_buffs.size() >= 4:
		return
	passive_buffs.append(buff)
	if player_ui:
		player_ui.add_passive_item(icon)

func _get_n_closest_enemies_in_cone(count: int, cone_angle: float = 60.0) -> Array:
	var first_enemy = _get_closest_enemy()
	if first_enemy == null:
		return []
	var first_direction = global_position.direction_to(first_enemy.global_position)
	var result = [first_enemy]
	if count <= 1:
		return result
	var enemies_with_distance = []
	for enemy in current_scene.enemy_list:
		if enemy == null or !is_instance_valid(enemy):
			continue
		if enemy == first_enemy:
			continue
		var dir_to_enemy = global_position.direction_to(enemy.global_position)
		var angle_diff = rad_to_deg(first_direction.angle_to(dir_to_enemy))
		if abs(angle_diff) <= cone_angle / 2.0:
			var dist = enemy.global_position.distance_to(global_position)
			enemies_with_distance.append({"enemy": enemy, "distance": dist})
	enemies_with_distance.sort_custom(func(a, b): return a.distance < b.distance)
	for i in range(min(count - 1, enemies_with_distance.size())):
		result.append(enemies_with_distance[i].enemy)
	return result


func _spawn_lightning_ball() -> void:
	if lightning_ball_scene == null:
		return
	var ball_count := 1
	var bounces := 2
	var dmg := get_crit_damage(current_attack)
	match lightning_ball_level:
		2: ball_count = 2; bounces = 3
		3: ball_count = 2; bounces = 5; dmg = get_crit_damage(current_attack * 1.5)
		4: ball_count = 3; bounces = 5; dmg = get_crit_damage(current_attack * 2.0)
		5: ball_count = 5; bounces = 8; dmg = get_crit_damage(current_attack * 2.5)
	var targets = _get_n_closest_enemies_in_cone(ball_count, 360.0)
	for i in range(ball_count):
		var delay = i * 0.15
		var target_enemy = targets[i] if i < targets.size() else null
		var d = dmg
		var lv = lightning_ball_level
		var b = bounces
		get_tree().create_timer(delay).timeout.connect(func():
			var ball = lightning_ball_scene.instantiate()
			ball.global_position = global_position
			ball.initial_target = target_enemy
			get_tree().root.get_node("Level").add_child(ball)
			ball.setup(d["damage"], d["is_crit"], b, lv)
		)

func _spawn_stars() -> void:
	var total_count = star_count + global_projectile_bonus
	for i in range(total_count):
		var delay = i * 0.3
		get_tree().create_timer(delay).timeout.connect(func(): _spawn_single_star())

func _spawn_single_star() -> void:
	if star_projectile_scene == null:
		return
	var crit_result = get_crit_damage(current_attack)
	var star = star_projectile_scene.instantiate()
	star.global_position = global_position
	star.damage = crit_result["damage"]
	star.is_crit = crit_result["is_crit"]
	star.speed = star_speed
	star.star_level = star_level
	current_scene.add_child(star)

func _spawn_wind_shurikens() -> void:
	var total_projectiles = wind_shuriken_count + global_projectile_bonus
	for i in range(total_projectiles):
		var delay = i * 0.2
		get_tree().create_timer(delay).timeout.connect(func(): _spawn_single_wind_shuriken())

func _spawn_single_wind_shuriken() -> void:
	if wind_shuriken_scene == null:
		return
	var random_angle = randf() * TAU
	var random_direction = Vector2(cos(random_angle), sin(random_angle))
	var crit_result = get_crit_damage(current_attack)
	var shuriken = wind_shuriken_scene.instantiate()
	shuriken.global_position = global_position
	shuriken.setup(self, crit_result["damage"], random_direction)
	shuriken.is_crit = crit_result["is_crit"]
	current_scene.add_child(shuriken)

func _spawn_knives() -> void:
	var total_projectiles = knife_projectile_count + global_projectile_bonus
	for i in range(total_projectiles):
		var delay = i * 0.2
		var vertical_offset = 10 if i % 2 == 0 else -10
		var horizontal_offset = i * 15
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_single_knife(vertical_offset, horizontal_offset)
		)

func _spawn_single_knife(vertical_offset: float = 0, horizontal_offset: float = 0) -> void:
	if knife_scene == null:
		return
	var crit_result = get_crit_damage(current_attack)
	var dir = direction if direction != Vector2.ZERO else (Vector2.RIGHT if facing_right else Vector2.LEFT)
	var perp = Vector2(-dir.y, dir.x)
	var new_knife = knife_scene.instantiate()
	new_knife.global_position = global_position + perp * vertical_offset
	new_knife.damage = crit_result["damage"]
	new_knife.is_crit = crit_result["is_crit"]
	new_knife.set_meta("direction", dir)
	current_scene.get_node("KnifeHolder").add_child(new_knife)

func _spawn_hammer() -> void:
	if hammer_scene == null:
		return
	var hammer_instance = hammer_scene.instantiate()
	hammer_instance.position = Vector2(80 if facing_right else -80, 0)
	hammer_instance.setup(self, current_attack, hammer_level, hammer_scale)
	add_child(hammer_instance)

func _spawn_magic_bullets(target_enemy: Area2D) -> void:
	var total_projectiles = magic_bullet_projectile_count + global_projectile_bonus
	var targets = _get_n_closest_enemies_in_cone(total_projectiles, 50.0)
	for i in range(targets.size()):
		var delay = i * 0.1
		var t = targets[i]
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_single_magic_bullet_at_target(t)
		)

func _spawn_single_magic_bullet_at_target(target_enemy: Area2D) -> void:
	if magic_bullet_scene == null:
		return
	if target_enemy == null or !is_instance_valid(target_enemy):
		return
	var crit_result = get_crit_damage(current_attack)
	var new_bullet = magic_bullet_scene.instantiate()
	new_bullet.global_position = global_position
	new_bullet.damage = crit_result["damage"]
	new_bullet.is_crit = crit_result["is_crit"]
	new_bullet.pierce_count = magic_bullet_pierce
	var dir = global_position.direction_to(target_enemy.global_position)
	new_bullet.set_meta("direction", dir)
	new_bullet.set_meta("magic_level", magic_bullet_level)
	current_scene.get_node("MagicBulletHolder").add_child(new_bullet)

func _spawn_holy_smites() -> void:
	for i in range(holy_smite_count):
		var delay = i * 0.3
		get_tree().create_timer(delay, false, false, true).timeout.connect(func(): _spawn_holy_smite())

func _spawn_holy_smite() -> void:
	if holy_smite_scene == null:
		return
	var enemies_in_range = get_tree().get_nodes_in_group("Enemy")
	if enemies_in_range.is_empty():
		return
	var valid_targets = []
	for enemy in enemies_in_range:
		if enemy != null and is_instance_valid(enemy):
			if "is_dying" in enemy and not enemy.is_dying:
				if enemy.visible:
					valid_targets.append(enemy)
	if valid_targets.is_empty():
		return
	for i in range(holy_smite_count):
		if valid_targets.is_empty():
			break
		var t = valid_targets.pick_random()
		var crit_result = get_crit_damage(current_attack)
		var smite = holy_smite_scene.instantiate()
		smite.damage = crit_result["damage"]
		smite.is_crit = crit_result["is_crit"]
		smite.setup(t.global_position)
		current_scene.add_child(smite)

func _get_random_enemy() -> Area2D:
	var valid_enemies = []
	for enemy in current_scene.enemy_list:
		if enemy != null and is_instance_valid(enemy):
			valid_enemies.append(enemy)
	if valid_enemies.size() == 0:
		return null
	return valid_enemies[randi() % valid_enemies.size()]

func _spawn_sword() -> void:
	if sword_level >= 5:
		if sword_aura_scene == null:
			return
		if sword_aura_instance == null or not is_instance_valid(sword_aura_instance):
			var crit_result = get_crit_damage(current_attack)
			sword_aura_instance = sword_aura_scene.instantiate()
			add_child(sword_aura_instance)
			sword_aura_instance.position = Vector2.ZERO
			sword_aura_instance.setup(self, crit_result["damage"])
	else:
		if sword_scene == null:
			return
		var crit_result = get_crit_damage(current_attack)
		var sword = sword_scene.instantiate()
		add_child(sword)
		sword.position = Vector2(60 if facing_right else -60, 0)
		sword.setup(self, crit_result["damage"], sword_level)
		sword.is_crit = crit_result["is_crit"]


func _apply_meta_upgrades() -> void:
	var meta := GameData.meta_upgrades
	might_multiplier = 1.0 + (meta["might"] * 0.10)
	base_hp += meta["max_hp"] * 50
	max_hp = base_hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	base_armor += meta["armor"] * 1.0
	current_armor = base_armor
	SPEED *= 1.0 + (meta["move_speed"] * 0.03)
	for key in ["hammer_cooldown", "magic_bullet_cooldown", "knife_cooldown",
				"holy_smite_cooldown", "sword_cooldown", "wind_shuriken_cooldown",
				"star_cooldown", "lightning_ball_cooldown"]:
		set(key, get(key) * pow(0.97, meta["attack_speed"]))
	recovery_rate = meta["recovery"] * 0.2
	magnet_range += meta["magnet"] * 15.0
	exp_multiplier += meta["greed"] * 0.05
	crit_chance += meta["crit"] * 0.02
	revivals_remaining = meta["revivals"]

func _tick_recovery(delta: float) -> void:
	if recovery_rate <= 0:
		return
	recovery_timer += delta
	if recovery_timer >= 1.0:
		recovery_timer = 0.0
		current_hp = min(current_hp + recovery_rate, max_hp)
		health_bar.value = current_hp

func SetStats() -> void:
	current_attack = base_attack
	current_armor = base_armor
	max_hp = base_hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func CollectExperience(amount: int) -> void:
	AudioManager.play_exp_sfx()
	var actual_exp = int(amount * exp_multiplier)
	current_exp += actual_exp
	total_exp_collected += actual_exp
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
	while current_exp >= exp_to_next_level:
		level_up()
		AudioManager.play_level_up()

func _calculate_exp_to_next_level(level: int) -> int:
	if level == 1:
		return 15
	elif level <= 30:
		return 15 + (level - 1) * 20
	elif level <= 55:
		return 15 + (29 * 20) + (level - 30) * 28
	else:
		return 15 + (29 * 20) + (25 * 28) + (level - 55) * 35

func level_up() -> void:
	player_level += 1
	current_exp -= exp_to_next_level
	exp_to_next_level = _calculate_exp_to_next_level(player_level)
	if level_up_effect_scene:
		var effect = level_up_effect_scene.instantiate()
		effect.position = Vector2.ZERO
		add_child(effect)
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
				_equip_weapon(hammer_scene, preload("res://Assets/Upgrades/ice_hammer.png"))
				hammer_timer = 0.0
			match hammer_level:
				2: current_attack += 2.0
				3: hammer_scale += 0.3
				4: hammer_cooldown *= 0.95
				5:
					current_attack += 2.0
					hammer_cooldown *= 0.90
					hammer_scale += 0.3
			hammer_timer = 0.0

		"magic_bullet":
			magic_bullet_level += 1
			if magic_bullet_level == 1:
				_equip_weapon(magic_bullet_scene, preload("res://Assets/magic_bullet.png"))
			match magic_bullet_level:
				2: magic_bullet_projectile_count += 1
				3:
					current_attack += 2.0
					magic_bullet_cooldown *= 0.90
				4:
					magic_bullet_projectile_count += 1
					current_attack += 5.0
				5:
					magic_bullet_projectile_count += 2
					current_attack += 3.0
					magic_bullet_cooldown *= 0.85
					magic_bullet_pierce = 1
			magic_bullet_timer = 0.0

		"knife":
			knife_level += 1
			if knife_level == 1:
				_equip_weapon(knife_scene, preload("res://Assets/knife_icon.png"))
			match knife_level:
				2: knife_projectile_count += 1
				3:
					current_attack += 2.0
					knife_cooldown *= 0.85
				4: knife_projectile_count += 1
				5:
					current_attack += 3.0
					knife_cooldown *= 0.80
			knife_timer = 0.0

		"holy_smite":
			holy_smite_level += 1
			if holy_smite_level == 1:
				_equip_weapon(holy_smite_scene, preload("res://Assets/Holy Smite/holysmite.png"))
			match holy_smite_level:
				2: holy_smite_count += 1
				3: current_attack += 3.0
				4: holy_smite_count += 1
				5:
					holy_smite_count += 3
					current_attack += 5.0
					holy_smite_aoe += 0.5
					holy_smite_cooldown = 0.5
			holy_smite_timer = 0.0

		"sword":
			sword_level += 1
			if sword_level == 1:
				_equip_weapon(sword_scene, preload("res://Assets/Sword/sword.png"))
			match sword_level:
				2: current_attack += 2.0
				3: sword_cooldown *= 0.85
				4: current_attack += 3.0
				5: current_attack += 5.0
			sword_timer = 0.0

		"wind_shuriken":
			wind_shuriken_level += 1
			if wind_shuriken_level == 1:
				_equip_weapon(wind_shuriken_scene, preload("res://Assets/Wind Shuriken/wind_shuriken.png"))
			match wind_shuriken_level:
				2: wind_shuriken_count += 1
				3: current_attack += 2.0
				4: wind_shuriken_count += 1
				5: current_attack += 3.0
			wind_shuriken_timer = 0.0

		"star":
			star_level += 1
			if star_level == 1:
				_equip_weapon(star_projectile_scene, preload("res://Assets/Bouncy thing/Star.png"))
			match star_level:
				2: star_count += 1
				3:
					current_attack += 2.0
					star_speed += 150.0
				4: star_count += 1
				5:
					star_count += 2
					current_attack += 5.0
					star_speed += 250.0
			star_timer = 0.0

		"lightning_ball":
			lightning_ball_level += 1
			if lightning_ball_level == 1:
				_equip_weapon(lightning_ball_scene, preload("res://Assets/lightningball.png"))
			lightning_ball_timer = 0.0

		"attack":
			current_attack += 5.0
			if not passive_buffs.has("attack"):
				_equip_passive("attack", preload("res://Assets/Upgrades/attk_up.png"))

		"attack_speed":
			attack_speed_multiplier *= 0.95
			if not passive_buffs.has("attack_speed"):
				_equip_passive("attack_speed", preload("res://Assets/Upgrades/attk_spd.png"))

		"move_speed":
			SPEED *= 1.05
			if not passive_buffs.has("move_speed"):
				_equip_passive("move_speed", preload("res://Assets/Upgrades/move_spd.png"))

		"max_hp":
			max_hp += 10
			current_hp += 10
			health_bar.max_value = max_hp
			health_bar.value = current_hp
			if not passive_buffs.has("max_hp"):
				_equip_passive("max_hp", preload("res://Assets/Upgrades/HP_up.png"))

		"more_projectile":
			global_projectile_bonus += 1
			if not passive_buffs.has("more_projectile"):
				_equip_passive("more_projectile", preload("res://Assets/Upgrades/duplicator.png"))

		"armor":
			current_armor += 1.0
			if not passive_buffs.has("armor"):
				_equip_passive("armor", preload("res://Assets/Upgrades/26.png"))

		"magnet":
			magnet_range += 100.0
			if not passive_buffs.has("magnet"):
				_equip_passive("magnet", preload("res://Assets/Upgrades/magnet.jpg"))

		"greed":
			exp_multiplier += 0.1
			if not passive_buffs.has("greed"):
				_equip_passive("greed", preload("res://Assets/Upgrades/greed.png"))

		"crit":
			crit_chance += 0.10
			if not passive_buffs.has("crit"):
				_equip_passive("crit", preload("res://Assets/Upgrades/crit.png"))

		"vampirism":
			vampirism += 1
			if not passive_buffs.has("vampirism"):
				_equip_passive("vampirism", preload("res://Assets/Upgrades/vampirism.png"))


func get_crit_damage(base_damage: float) -> Dictionary:
	var scaled := base_damage * might_multiplier
	var is_crit = randf() < crit_chance
	var damage = scaled * 2.0 if is_crit else scaled
	return {"damage": damage, "is_crit": is_crit}

func TakeDamage(damage: float) -> void:
	var actual_damage = max(0.05, damage - current_armor)
	current_hp -= actual_damage
	current_hp = max(0, current_hp)
	health_bar.value = current_hp
	flash_timer = FLASH_DURATION
	if current_hp <= 0:
		Die()

func Die() -> void:
	if revivals_remaining > 0:
		revivals_remaining -= 1
		current_hp = int(max_hp * 0.25)
		health_bar.value = current_hp
		return
	var level = get_tree().root.get_node("Level")
	if level and level.has_method("show_game_over"):
		level.show_game_over(self)
	else:
		get_tree().change_scene_to_file("res://game_over.tscn")
