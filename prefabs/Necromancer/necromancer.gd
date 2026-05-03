extends CharacterBody2D
class_name Necromancer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var damage_number_scene: PackedScene
@export var magic_circle_scene: PackedScene

var current_scene
var player_ref
var max_hp: int = 100
var current_hp: int = 100
var flash_timer: float = 0.0
var is_dying: bool = false
var exp_value: int = 50

const SPEED: float = 120.0
const MIN_DISTANCE: float = 300.0
const MAX_DISTANCE: float = 400.0
const SUMMON_COOLDOWN: float = 5.0
const FLASH_DURATION: float = 0.1

var summon_timer: float = 0.0
var is_summoning: bool = false
var has_spawned_circle: bool = false

func _ready() -> void:
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
	
	if is_summoning:
		velocity = Vector2.ZERO
	else:
		summon_timer -= delta
		
		if summon_timer <= 0:
			start_summon()
		else:
			maintain_distance()
	
	move_and_slide()

func maintain_distance() -> void:
	var distance = global_position.distance_to(player_ref.global_position)
	var dir = global_position.direction_to(player_ref.global_position)
	
	if distance < MIN_DISTANCE:
		velocity = -dir * SPEED
		if sprite.animation != "run":
			sprite.play("run")
	elif distance > MAX_DISTANCE:
		velocity = dir * SPEED
		if sprite.animation != "run":
			sprite.play("run")
	else:
		velocity = Vector2.ZERO
		if sprite.animation != "default":
			sprite.play("default")
	
	if dir.x != 0:
		sprite.flip_h = dir.x > 0

func start_summon() -> void:
	is_summoning = true
	has_spawned_circle = false
	sprite.play("summon")

func _on_frame_changed() -> void:
	if sprite.animation == "summon" and sprite.frame == 8 and not has_spawned_circle:
		spawn_magic_circle()
		has_spawned_circle = true

func spawn_magic_circle() -> void:
	if magic_circle_scene == null:
		return
	
	var circle = magic_circle_scene.instantiate()
	circle.global_position = global_position + Vector2(0, 50)
	current_scene.add_child(circle)

func _on_animation_finished() -> void:
	if sprite.animation == "summon":
		is_summoning = false
		summon_timer = SUMMON_COOLDOWN
		sprite.play("default")
	elif sprite.animation == "death":
		on_death()

func TakeDamage(damage: float) -> void:
	if is_dying:
		return
	
	current_hp -= damage
	flash_timer = FLASH_DURATION
	spawn_damage_number(damage)
	
	if current_hp <= 0:
		is_dying = true
		sprite.play("death")

func apply_flash(intensity: float):
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)

func spawn_damage_number(damage: float):
	if damage_number_scene == null:
		return
	
	var dmg_num = damage_number_scene.instantiate()
	var spawn_pos = global_position + Vector2(randf_range(-10, 10), -20)
	current_scene.add_child(dmg_num)
	dmg_num.setup(damage, spawn_pos)

func on_death() -> void:
	current_scene.enemy_died.emit(self)
	queue_free()
