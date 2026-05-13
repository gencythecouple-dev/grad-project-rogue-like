extends Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var horizontal_slash: CollisionShape2D = $Attack1
@onready var vertical_slash: CollisionShape2D = $Attack2
var damage: float = 10.0
var player: CharacterBody2D
var sword_level: int = 1
var hit_enemies: Array = []
var is_crit: bool = false
func _ready() -> void:
	monitoring = true
	horizontal_slash.disabled = true
	vertical_slash.disabled = true
	area_entered.connect(_on_area_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
func _on_frame_changed() -> void:
	if sword_level >= 2:
		if sprite.frame >= 2 and sprite.frame <= 5:
			horizontal_slash.disabled = false
			vertical_slash.disabled = true
		elif sprite.frame >= 6 and sprite.frame <= 9:
			horizontal_slash.disabled = true
			vertical_slash.disabled = false
		else:
			horizontal_slash.disabled = true
			vertical_slash.disabled = true
	else:
		vertical_slash.disabled = true
		if sprite.frame >= 2 and sprite.frame <= 5:
			horizontal_slash.disabled = false
		else:
			horizontal_slash.disabled = true
func setup(spawn_player: CharacterBody2D, spawn_damage: float, level: int) -> void:
	player = spawn_player
	damage = spawn_damage
	sword_level = level
	sprite.flip_h = !spawn_player.facing_right
	
	if level >= 2:
		sprite.play("attack2")
	else:
		sprite.play("attack1")
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if hit_enemies.has(area):
			return
		if "is_dying" in area and area.is_dying:
			return
		
		hit_enemies.append(area)
		area.TakeDamage(damage, is_crit)
		player.total_damage_dealt += damage
func _on_animation_finished() -> void:
	hide()
	queue_free()
