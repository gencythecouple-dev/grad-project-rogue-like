extends Area2D
class_name WindShuriken

var damage: float = 5.0
var player: CharacterBody2D
var hit_enemies: Array = []

var start_pos: Vector2
var throw_direction: Vector2
var lifetime: float = 0.0
var max_lifetime: float = 2.0
var curve_strength: float = 200.0
var is_crit: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("default")

func setup(spawn_player: CharacterBody2D, spawn_damage: float, spawn_direction: Vector2) -> void:
	player = spawn_player
	damage = spawn_damage
	start_pos = global_position
	throw_direction = spawn_direction

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	var progress = lifetime / max_lifetime
	
	if progress >= 1.0:
		queue_free()
		return
	
	var forward = throw_direction * 300.0 * sin(progress * PI)
	var sideways = Vector2(-throw_direction.y, throw_direction.x) * curve_strength * sin(progress * PI * 2.0)
	
	if player and is_instance_valid(player):
		var target_pos = player.global_position if progress > 0.5 else start_pos
		var curve_pos = start_pos + forward + sideways
		global_position = lerp(curve_pos, target_pos, max(0, (progress - 0.5) * 2.0))
	else:
		global_position = start_pos + forward + sideways

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if hit_enemies.has(body):
			return
		if "is_dying" in body and body.is_dying:
			return
		
		hit_enemies.append(body)
		body.TakeDamage(damage,is_crit)
		
		if player:
			player.total_damage_dealt += damage
