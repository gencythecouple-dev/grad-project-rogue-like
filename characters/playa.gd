extends CharacterBody2D

var SPEED := 200

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
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




var flash_timer: float = 0.0
const FLASH_DURATION: float = 0.1
var target: CharacterBody2D
var current_scene: Node
var player_ui  
var level_up_menu

#self-explainatory
var active_weapons: Array = []
var passive_buffs: Array = []

#directional stuff
var direction := Vector2.ZERO
var facing_right := true
var last_direction := Vector2.RIGHT

#player stats
var base_attack: float = 3.0
var current_attack: float
var base_armor: float = 5.0
var current_armor: float
var base_hp := 200
var max_hp: int
var current_hp: int



var magic_bullet_projectile_count: int = 1
var knife_projectile_count: int = 1
var arrow_projectile_count: int = 1
var global_projectile_bonus = 0
var hammer_scale: float = 1.0
var hammer_level: int = 0

#magic bullet
var magic_bullet_level: int = 0
var magic_bullet_pierce: int = 0

#knife
var knife_level: int = 0

#Holy Smite
var holy_smite_level: int = 0
var holy_smite_count: int = 1
var holy_smite_aoe: float = 1.0
var holy_smite_ready: bool = true


#Sword
var sword_level: int = 0


#Wind Shuriken
var wind_shuriken_level: int = 0
var wind_shuriken_count: int = 1

#Star Projetile
var star_level: int = 0
var star_count: int = 1
var star_speed: float = 300
var star_ready: bool = true


#player exp and level
var current_exp: int = 0
var exp_to_next_level: int = 20
var player_level: int = 1

#end game summary
var total_damage_dealt: float = 0.0
var total_kills: int = 0
var total_exp_collected: int = 0

#Passives
var magnet_range: float = 50.0
var exp_multiplier: float = 1.0
var crit_chance: float = 0.0
var vampirism: int = 0



func _ready() -> void:
	SetStats()
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
		
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	
	update_animation()
	update_facing()
	move_and_slide()
	
func apply_flash(intensity: float):
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






#ATTACK AND WEAPONS

func Attack() -> void:
	var target_enemy = _get_closest_enemy()
	if target_enemy == null:
		return
	
	for weapon in active_weapons:
		if weapon == hammer_scene:
			_spawn_hammer()
		elif weapon == magic_bullet_scene:
			_spawn_magic_bullets(target_enemy)
		elif weapon == knife_scene:
			_spawn_knives()
		elif weapon == holy_smite_scene:
			if holy_smite_ready:
				_spawn_holy_smites()
				holy_smite_ready = false
				get_tree().create_timer(5.0).timeout.connect(func(): holy_smite_ready = true)
		elif weapon == sword_scene:
			_spawn_sword()
		elif weapon == wind_shuriken_scene:
			_spawn_wind_shurikens()
		elif weapon == star_projectile_scene:
			if star_ready:
				_spawn_stars()
				star_ready = false
				get_tree().create_timer(5.0).timeout.connect(func(): star_ready = true)


func _spawn_stars() -> void:
	var total_count = star_count + global_projectile_bonus
	for i in range(total_count):
		var delay = i * 0.3
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_single_star()
		)

func _spawn_single_star() -> void:
	if star_projectile_scene == null:
		return
	
	var crit_result = get_crit_damage(current_attack)
	
	var star = star_projectile_scene.instantiate()
	star.global_position = global_position
	star.damage = crit_result["damage"]
	star.is_crit = crit_result["is_crit"]
	star.speed = star_speed
	current_scene.add_child(star)

func _spawn_wind_shurikens() -> void:
	var total_projectiles = wind_shuriken_count + global_projectile_bonus
	
	for i in range(total_projectiles):
		var delay = i * 0.2
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_single_wind_shuriken()
		)

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
	
	var new_knife = knife_scene.instantiate()
	new_knife.global_position = global_position
	new_knife.damage = crit_result["damage"]
	new_knife.is_crit = crit_result["is_crit"]
	
	var dir = last_direction if last_direction != Vector2.ZERO else Vector2.RIGHT
	new_knife.set_meta("direction", dir)
	
	current_scene.get_node("KnifeHolder").add_child(new_knife)

func _spawn_knife_at_direction(angle_offset: float) -> void:
	if knife_scene == null:
		return
	var new_knife = knife_scene.instantiate()
	new_knife.global_position = global_position
	new_knife.damage = get_crit_damage(current_attack)
	
	var dir = last_direction.rotated(deg_to_rad(angle_offset))
	new_knife.set_meta("direction", dir)
	
	current_scene.get_node("KnifeHolder").add_child(new_knife)

func _spawn_hammer() -> void:
	if hammer_scene == null:
		return
	
	var hammer_instance = hammer_scene.instantiate()
	hammer_instance.position = Vector2(80 if facing_right else -80, 0)
	hammer_instance.setup(self, current_attack, hammer_level, hammer_scale)
	add_child(hammer_instance)

func _spawn_magic_bullets(target_enemy: CharacterBody2D) -> void:
	var total_projectiles = magic_bullet_projectile_count + global_projectile_bonus
	var targets = _get_n_closest_enemies_in_cone(total_projectiles, 50.0)
	
	for i in range(targets.size()):
		var delay = i * 0.1
		var target = targets[i]
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_single_magic_bullet_at_target(target)
		)

func _spawn_single_magic_bullet_at_target(target: CharacterBody2D) -> void:
	if magic_bullet_scene == null:
		return
	if target == null or !is_instance_valid(target):
		return
	
	var crit_result = get_crit_damage(current_attack)
	
	var new_bullet = magic_bullet_scene.instantiate()
	new_bullet.global_position = global_position
	new_bullet.damage = crit_result["damage"]
	new_bullet.is_crit = crit_result["is_crit"]
	new_bullet.pierce_count = magic_bullet_pierce
	
	var dir = global_position.direction_to(target.global_position)
	new_bullet.set_meta("direction", dir)
	new_bullet.set_meta("magic_level", magic_bullet_level)
	
	current_scene.get_node("MagicBulletHolder").add_child(new_bullet)


func _spawn_magic_bullet_at_position(target_pos: Vector2, angle_offset: float) -> void:
	if magic_bullet_scene == null:
		return
	var new_bullet = magic_bullet_scene.instantiate()
	new_bullet.global_position = global_position
	new_bullet.damage = get_crit_damage(current_attack)
	new_bullet.pierce_count = magic_bullet_pierce
	var dir = global_position.direction_to(target_pos)
	dir = dir.rotated(deg_to_rad(angle_offset))
	new_bullet.set_meta("direction", dir)
	new_bullet.set_meta("magic_level", magic_bullet_level)
	current_scene.get_node("MagicBulletHolder").add_child(new_bullet)

func _spawn_holy_smites() -> void:
	for i in range(holy_smite_count):
		var delay = i * 0.3
		get_tree().create_timer(delay).timeout.connect(
			func(): _spawn_holy_smite()
		)

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
				valid_targets.append(enemy)
	
	if valid_targets.is_empty():
		return
	
	for i in range(holy_smite_count):
		if valid_targets.is_empty():
			break
		
		var target = valid_targets.pick_random()
		var crit_result = get_crit_damage(current_attack)
		
		var smite = holy_smite_scene.instantiate()
		smite.global_position = target.global_position
		smite.damage = crit_result["damage"]
		smite.is_crit = crit_result["is_crit"]
		current_scene.add_child(smite)

func _get_random_enemy() -> CharacterBody2D:
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
		
		var crit_result = get_crit_damage(current_attack)
		
		var sword_aura = sword_aura_scene.instantiate()
		add_child(sword_aura)
		sword_aura.position = Vector2.ZERO
		sword_aura.setup(self, crit_result["damage"])
		sword_aura.is_crit = crit_result["is_crit"]
	else:
		if sword_scene == null:
			return
		
		var crit_result = get_crit_damage(current_attack)
		
		var sword = sword_scene.instantiate()
		add_child(sword)
		sword.position = Vector2(60 if facing_right else -60, 0)
		sword.setup(self, crit_result["damage"], sword_level)
		sword.is_crit = crit_result["is_crit"]

#STATS AND LEVELING
func SetStats() -> void:
	current_attack = base_attack
	current_armor = base_armor
	max_hp = base_hp
	current_hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func CollectExperience(amount: int) -> void:
	var actual_exp = int(amount * exp_multiplier)
	current_exp += actual_exp
	total_exp_collected += actual_exp
	if player_ui:
		player_ui.update_exp(current_exp, exp_to_next_level)
	while current_exp >= exp_to_next_level:
		level_up()

func _calculate_exp_to_next_level(level: int) -> int:
	if level == 1:
		return 10
	elif level <= 30:
		return 10 + (level - 1) * 10
	elif level <= 55:
		return 10 + (29 * 10) + (level - 30) * 13
	else:
		return 10 + (29 * 10) + (25 * 13) + (level - 55) * 16

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
			match hammer_level:
				2: current_attack += 2.0
				3: hammer_scale += 0.3
				4: attack_timer.wait_time *= 0.95
				5:
					current_attack += 2.0
					attack_timer.wait_time *= 0.90
					hammer_scale += 0.3
		
		"magic_bullet":
			magic_bullet_level += 1
			if magic_bullet_level == 1:
				_equip_weapon(magic_bullet_scene, preload("res://Assets/magic_bullet.png"))
			match magic_bullet_level:
				2: magic_bullet_projectile_count += 1
				3:
					current_attack += 2.0
					attack_timer.wait_time *= 0.90
				4: magic_bullet_projectile_count += 1
				5:
					current_attack += 3.0
					attack_timer.wait_time *= 0.85
					magic_bullet_pierce = 1
		
		"knife":
			knife_level += 1
			if knife_level == 1:
				_equip_weapon(knife_scene, preload("res://Assets/knife_icon.png"))
			match knife_level:
				2: knife_projectile_count += 1
				3:
					current_attack += 2.0
					attack_timer.wait_time *= 0.85
				4: knife_projectile_count += 1
				5:
					current_attack += 3.0
					attack_timer.wait_time *= 0.80
		
		"holy_smite":
			holy_smite_level += 1
			if holy_smite_level == 1:
				_equip_weapon(holy_smite_scene, preload("res://Assets/Holy Smite/holysmite.png"))
			match holy_smite_level:
				2: holy_smite_count += 1
				3: current_attack += 3.0
				4: holy_smite_count += 1
				5:
					current_attack += 5.0
					holy_smite_aoe += 0.5
		
		"sword":
			sword_level += 1
			if sword_level == 1:
				_equip_weapon(sword_scene, preload("res://Assets/Sword/sword.png"))
			match sword_level:
				2: current_attack += 2.0
				3: attack_timer.wait_time *= 0.85
				4: current_attack += 3.0
				5: current_attack += 5.0
		
		"wind_shuriken":
			wind_shuriken_level += 1
			if wind_shuriken_level == 1:
				_equip_weapon(wind_shuriken_scene, preload("res://Assets/Wind Shuriken/wind_shuriken.png"))
			match wind_shuriken_level:
				2: wind_shuriken_count += 1
				3: current_attack += 2.0
				4: wind_shuriken_count += 1
				5: current_attack += 3.0
		
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
					current_attack += 5.0
					star_speed += 250.0
		
		"attack":
			current_attack += 1.0
			if not passive_buffs.has("attack"):
				_equip_passive("attack", preload("res://Assets/Upgrades/attk_up.png"))
		

		
		"attack_speed":
			attack_timer.wait_time *= 0.95
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
			magnet_range += 200.0
			if not passive_buffs.has("magnet"):
				_equip_passive("magnet", preload("res://Assets/Upgrades/magnet.jpg"))
		
		"greed":
			exp_multiplier += 0.1
			if not passive_buffs.has("greed"):
				_equip_passive("greed", preload("res://Assets/Upgrades/greed.png"))
		
		"crit":
			crit_chance += 0.05
			if not passive_buffs.has("crit"):
				_equip_passive("crit", preload("res://Assets/Upgrades/crit.png"))
		
		"vampirism":
			vampirism += 1
			if not passive_buffs.has("vampirism"):
				_equip_passive("vampirism", preload("res://Assets/Upgrades/vampirism.png"))

#Passive
func get_crit_damage(base_damage: float) -> Dictionary:
	var is_crit = randf() < crit_chance
	var damage = base_damage * 2.0 if is_crit else base_damage
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
	var level = get_tree().root.get_node("Level")
	if level and level.has_method("show_game_over"):
		level.show_game_over(self)
	else:
		get_tree().change_scene_to_file("res://game_over.tscn")

func _on_attack_timer_timeout() -> void:
	Attack()
	attack_timer.start()
