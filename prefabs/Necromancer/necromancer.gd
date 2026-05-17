extends Area2D
class_name Necromancer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var damage_number_scene: PackedScene
@export var summoncircle_scene: PackedScene

var current_scene
var player_ref
var max_hp: int = 1500
var current_hp: int = 1500
var flash_timer: float = 0.0
var is_dying: bool = false
var exp_value: int = 50
var active_totems: int = 0

const MAX_TOTEMS: int = 3
const INITIAL_SPEED: float = 200.0
const CHASE_SPEED: float = 100.0
var SPEED: float = INITIAL_SPEED
const MIN_DISTANCE: float = 500.0
const MAX_DISTANCE: float = 600.0
const SUMMON_COOLDOWN: float = 5.0
const FLASH_DURATION: float = 0.1
const HEALTH_REGEN_PER_SECOND: float = 2.0

var summon_timer: float = 0.0
var is_summoning: bool = false
var has_spawned_circle: bool = false
var has_summoned_once: bool = false
var regen_timer: float = 0.0

func _ready() -> void:
	add_to_group("Necromancer")
	add_to_group("Boss")
	current_scene = get_tree().root.get_node("Level")
	player_ref = get_tree().get_first_node_in_group("Player")
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	
	sprite.play("default")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	
	summon_timer = SUMMON_COOLDOWN

func _physics_process(delta: float) -> void:
	if player_ref == null or is_dying:
		return
	
	if flash_timer > 0:
		flash_timer -= delta
		apply_flash(flash_timer / FLASH_DURATION)
	
	regen_timer += delta
	if regen_timer >= 1.0:
		heal(HEALTH_REGEN_PER_SECOND)
		regen_timer = 0.0
	
	if is_summoning:
		pass
	else:
		summon_timer -= delta
		if summon_timer <= 0:
			start_summon()
		else:
			maintain_distance(delta)

func maintain_distance(delta: float) -> void:
	var distance = global_position.distance_to(player_ref.global_position)
	var dir = global_position.direction_to(player_ref.global_position)
	
	if distance < MIN_DISTANCE - 50:
		global_position += -dir * SPEED * delta
		if sprite.animation != "run":
			sprite.play("run")
		sprite.flip_h = dir.x > 0
	elif distance > MAX_DISTANCE + 50:
		global_position += dir * SPEED * delta
		if sprite.animation != "run":
			sprite.play("run")
		sprite.flip_h = dir.x < 0
	else:
		if sprite.animation != "default":
			sprite.play("default")

func start_summon() -> void:
	if active_totems >= MAX_TOTEMS:
		summon_timer = SUMMON_COOLDOWN
		return
	
	is_summoning = true
	has_spawned_circle = false
	sprite.play("summon")
	
	if not has_summoned_once:
		has_summoned_once = true
		SPEED = CHASE_SPEED

func _on_frame_changed() -> void:
	if sprite.animation == "summon" and sprite.frame == 8 and not has_spawned_circle:
		spawn_magic_circle()
		has_spawned_circle = true

func spawn_magic_circle() -> void:
	if summoncircle_scene == null:
		return
	
	var circle = summoncircle_scene.instantiate()
	circle.global_position = global_position + Vector2(0, 50)
	current_scene.add_child(circle)

func _on_animation_finished() -> void:
	if sprite.animation == "summon":
		is_summoning = false
		summon_timer = SUMMON_COOLDOWN
		sprite.play("default")
	elif sprite.animation == "death":
		on_death()

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)

func TakeDamage(damage: float, is_crit: bool = false) -> void:
	if is_dying:
		return
	
	current_hp -= damage
	flash_timer = FLASH_DURATION
	spawn_damage_number(damage, is_crit)
	
	if current_hp <= 0:
		is_dying = true
		sprite.play("death")

func apply_flash(intensity: float):
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)

func spawn_damage_number(damage: float, is_crit: bool = false):
	if damage_number_scene == null:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos, is_crit)

func on_death() -> void:
	current_scene.enemy_died.emit(self)
	queue_free()
