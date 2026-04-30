extends Area2D
class_name WindShuriken

var speed: float = 400.0
var damage: float = 5.0
var player: CharacterBody2D
var direction: Vector2
var lifetime: float = 0.0
var max_lifetime: float = 2.0
var hit_enemies: Array = []

var outbound_time: float = 0.8
var is_returning: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("default")

func setup(spawn_player: CharacterBody2D, spawn_damage: float, spawn_direction: Vector2) -> void:
	player = spawn_player
	damage = spawn_damage
	direction = spawn_direction

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	if lifetime >= outbound_time and not is_returning:
		is_returning = true
	
	if is_returning:
		if player and is_instance_valid(player):
			direction = global_position.direction_to(player.global_position)
			
			if global_position.distance_to(player.global_position) < 30:
				queue_free()
				return
	
	rotation += delta * 15.0
	position += direction * speed * delta
	
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if hit_enemies.has(body):
			return
		if "is_dying" in body and body.is_dying:
			return
		
		hit_enemies.append(body)
		body.TakeDamage(damage)
		
		if player:
			player.total_damage_dealt += damage
