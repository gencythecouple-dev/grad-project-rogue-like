extends StaticBody2D
class_name ObstacleBase

const DROP_TABLE = [
	{"type": "gold", "weight": 63},
	{"type": "gem", "weight": 25},
	{"type": "gem_pretty", "weight": 2},
	{"type": "magnet", "weight": 8},
	{"type": "power_up", "weight": 2},
]

const FLASH_DURATION: float = 0.1

var hp: int = 1
var is_dead: bool = false
var flash_timer: float = 0.0
var cached_sprite: Node2D = null

@export var gold_scene: PackedScene
@export var magnet_scene: PackedScene
@export var power_up_scene: PackedScene

func _ready() -> void:
	add_to_group("Obstacle")
	$HitArea.area_entered.connect(_on_area_entered)
	if has_node("AnimatedSprite2D"):
		cached_sprite = get_node("AnimatedSprite2D")
	elif has_node("Sprite2D"):
		cached_sprite = get_node("Sprite2D")
	if cached_sprite and cached_sprite.material:
		cached_sprite.material = cached_sprite.material.duplicate()
	collision_layer = 8
	collision_mask = 3
	set_deferred("collision_layer", 8)
	set_deferred("collision_mask", 3)

func _process(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		_apply_flash(flash_timer / FLASH_DURATION)

func _apply_flash(intensity: float) -> void:
	if cached_sprite == null:
		return
	var mat: ShaderMaterial
	if cached_sprite is AnimatedSprite2D:
		mat = cached_sprite.material as ShaderMaterial
	elif cached_sprite is Sprite2D:
		mat = cached_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flash_intensity", intensity)

func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	if area.collision_layer == 4:
		take_damage()

func take_damage() -> void:
	hp -= 1
	flash_timer = FLASH_DURATION
	AudioManager.play_hit()
	if hp <= 0:
		die()

func die() -> void:
	is_dead = true
	flash_timer = FLASH_DURATION
	remove_from_group("Obstacle")
	await get_tree().create_timer(FLASH_DURATION).timeout
	_spawn_drop()
	queue_free()

func _spawn_drop() -> void:
	var drop = _roll_drop()
	var scene: PackedScene
	var animation: String
	var amount: int
	match drop:
		"gold":
			scene = gold_scene
			animation = "coin"
			amount = 5
		"gem":
			scene = gold_scene
			animation = "gem"
			amount = 50
		"gem_pretty":
			scene = gold_scene
			animation = "gem_pretty"
			amount = 100
		"magnet":
			scene = magnet_scene
			animation = "default"
			amount = 0
		"power_up":
			scene = power_up_scene
			animation = "default"
			amount = 0
	if scene == null:
		return
	var instance = scene.instantiate()
	instance.global_position = global_position
	get_tree().root.get_node("Level").add_child(instance)
	instance.setup(amount, animation)
	

func _roll_drop() -> String:
	var total_weight: int = 0
	for entry in DROP_TABLE:
		total_weight += entry["weight"]
	var roll := randi() % total_weight
	var cumulative: int = 0
	for entry in DROP_TABLE:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["type"]
	return "gold"
