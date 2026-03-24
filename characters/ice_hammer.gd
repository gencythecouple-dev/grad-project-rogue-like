extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $Timer

var damage: float = 10.0
var player: CharacterBody2D
var hammer_level: int = 1

func _ready() -> void:
	monitoring = false
	lifetime_timer.wait_time = 1.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	sprite.play("swing")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	lifetime_timer.start()

func _on_frame_changed() -> void:
	if sprite.frame == 8:
		monitoring = true
	elif sprite.frame == 9:
		monitoring = false

func setup(spawn_player: CharacterBody2D, spawn_damage: float, level: int, scale_mult: float) -> void:
	player = spawn_player
	damage = spawn_damage
	hammer_level = level
	sprite.scale = Vector2(scale_mult, scale_mult)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.TakeDamage(damage)

func _on_animation_finished() -> void:
	hide()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
