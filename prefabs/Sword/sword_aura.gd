extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var damage: float = 10.0
var player: CharacterBody2D
var hit_enemies: Array = []
var is_crit: bool = false

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	sprite.play("default")
	sprite.animation_finished.connect(_on_animation_finished)

func setup(spawn_player: CharacterBody2D, spawn_damage: float) -> void:
	player = spawn_player
	damage = spawn_damage

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if hit_enemies.has(body):
			return
		if "is_dying" in body and body.is_dying:
			return
		
		hit_enemies.append(body)
		body.TakeDamage(damage,is_crit)
		player.total_damage_dealt += damage

func _on_animation_finished() -> void:
	queue_free()
