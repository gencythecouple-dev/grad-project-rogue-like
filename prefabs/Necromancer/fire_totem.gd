extends Area2D
class_name FireTotem

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var buff_area: Area2D = $BuffArea
@export var damage_number_scene: PackedScene

var current_scene
var player_ref
var max_hp: int = 70
var current_hp: int = 70
var flash_timer: float = 0.0
var is_dying: bool = false
var exp_value: int = 15
var lifetime: float = 0.0

const BUFF_INTERVAL: float = 3.0
const BUFF_RADIUS: float = 200.0
const SPEED_MULTIPLIER: float = 1.3
const ARMOR_BONUS: float = 2.0
const FLASH_DURATION: float = 0.1
const TOTEM_LIFETIME: float = 20.0

var buff_timer: float = 0.0
var is_buffing: bool = false
var has_applied_buff: bool = false
var buffed_enemies: Array = []

func _ready() -> void:
	add_to_group("Enemy")
	collision_layer = 2
	collision_mask = 0
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	
	# Spread totems so they don't stack
	global_position += Vector2(randf_range(-80, 80), randf_range(-80, 80))
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	
	sprite.play("summon")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	
	buff_area.area_entered.connect(_on_buff_area_entered)
	buff_area.area_exited.connect(_on_buff_area_exited)
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = BUFF_RADIUS
	var collision = buff_area.get_node("CollisionShape2D")
	collision.shape = circle_shape

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= TOTEM_LIFETIME:
		on_death()
		return
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	if not is_buffing:
		buff_timer += delta
		if buff_timer >= BUFF_INTERVAL:
			start_buff()

func start_buff() -> void:
	is_buffing = true
	has_applied_buff = false
	buff_timer = 0.0
	sprite.play("buff")

func _on_frame_changed() -> void:
	if sprite.animation == "buff" and sprite.frame == 8 and not has_applied_buff:
		apply_buffs()
		has_applied_buff = true

func apply_buffs() -> void:
	for enemy in buffed_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if "is_dying" in enemy and enemy.is_dying:
			continue
		if not enemy.has_meta("totem_buffed"):
			enemy.set_meta("totem_buffed", true)
			enemy.set_meta("original_speed", enemy.speed)
			enemy.speed *= SPEED_MULTIPLIER
			if "current_armor" in enemy:
				enemy.set_meta("original_armor", enemy.current_armor)
				enemy.current_armor += ARMOR_BONUS
			if enemy.has_node("AnimatedSprite2D"):
				var spr = enemy.get_node("AnimatedSprite2D")
				if spr.material is ShaderMaterial:
					spr.material.set_shader_parameter("buff_tint", Vector3(1.3, 0.6, 0.5))

func _on_animation_finished() -> void:
	if sprite.animation == "summon":
		sprite.play("idle")
	elif sprite.animation == "buff":
		is_buffing = false
		sprite.play("idle")

func _on_buff_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") and not area.is_in_group("Boss") and not area is FireTotem:
		if not buffed_enemies.has(area):
			buffed_enemies.append(area)

func _on_buff_area_exited(area: Area2D) -> void:
	if area.is_in_group("Enemy") and not area.is_in_group("Boss") and not area is FireTotem:
		remove_buff_from_enemy(area)
		buffed_enemies.erase(area)

func remove_buff_from_enemy(enemy: Node2D) -> void:
	if enemy.has_meta("totem_buffed"):
		enemy.remove_meta("totem_buffed")
		if enemy.has_meta("original_speed"):
			enemy.speed = enemy.get_meta("original_speed")
			enemy.remove_meta("original_speed")
		if enemy.has_meta("original_armor") and "current_armor" in enemy:
			enemy.current_armor = enemy.get_meta("original_armor")
			enemy.remove_meta("original_armor")
		if enemy.has_meta("damage_multiplier"):
			enemy.remove_meta("damage_multiplier")
		if enemy.has_node("AnimatedSprite2D"):
			var spr = enemy.get_node("AnimatedSprite2D")
			if spr.material is ShaderMaterial:
				spr.material.set_shader_parameter("buff_tint", Vector3(1.0, 1.0, 1.0))

func TakeDamage(damage: float, is_crit: bool = false) -> void:
	if is_dying:
		return
	current_hp -= damage
	flash_timer = FLASH_DURATION
	spawn_damage_number(damage, is_crit)
	if current_hp <= 0:
		is_dying = true
		on_death()

func apply_flash(intensity: float) -> void:
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)

func spawn_damage_number(damage: float, is_crit: bool = false) -> void:
	if damage_number_scene == null:
		return
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos: Vector2 = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos, is_crit)

func on_death() -> void:
	for enemy in buffed_enemies:
		remove_buff_from_enemy(enemy)
	current_scene.enemy_died.emit(self)
	queue_free()
