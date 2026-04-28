extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $Timer

var damage: float = 10.0
var player: CharacterBody2D
var sword_level: int = 1
var hit_enemies: Array = []

func _ready() -> void:
	monitoring = false
	lifetime_timer.wait_time = 1.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	lifetime_timer.start()

func _on_frame_changed() -> void:
	if sword_level < 5:
		if sprite.frame >= 2 and sprite.frame <= 5:
			monitoring = true
		else:
			monitoring = false
	else:
		monitoring = true

func setup(spawn_player: CharacterBody2D, spawn_damage: float, level: int) -> void:
	player = spawn_player
	damage = spawn_damage
	sword_level = level
	sprite.flip_h = !spawn_player.facing_right
	
	if level >= 5:
		sprite.play("circular")
	elif level >= 2:
		sprite.play("cross_slash")
	else:
		sprite.play("horizontal_slash")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if hit_enemies.has(body):
			return
		if "is_dying" in body and body.is_dying:
			return
		
		hit_enemies.append(body)
		body.TakeDamage(damage)
		player.total_damage_dealt += damage

func _on_animation_finished() -> void:
	hide()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()


func _on_animated_sprite_2d_frame_changed() -> void:
	pass # Replace with function body.
