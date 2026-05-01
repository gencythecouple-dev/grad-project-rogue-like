extends Area2D
class_name StarProjectile

var speed: float = 300.0
var damage: float = 3.0
var velocity: Vector2
var hit_enemies: Array = []
var lifetime: float = 0.0
var max_lifetime: float = 10.0

var trail_points: Array = []
var max_trail_length: int = 60

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("default")
	
	var random_angle = randf() * TAU
	velocity = Vector2(cos(random_angle), sin(random_angle)) * speed

func _physics_process(delta: float) -> void:
	lifetime += delta
	
	if lifetime >= max_lifetime:
		queue_free()
		return
	
	position += velocity * delta
	
	var viewport_rect = get_viewport_rect()
	var cam = get_viewport().get_camera_2d()
	if cam:
		var cam_pos = cam.global_position
		var half_size = viewport_rect.size / (2.0 * cam.zoom)
		
		if global_position.x <= cam_pos.x - half_size.x or global_position.x >= cam_pos.x + half_size.x:
			velocity.x *= -1
		if global_position.y <= cam_pos.y - half_size.y or global_position.y >= cam_pos.y + half_size.y:
			velocity.y *= -1
	
	trail_points.append(global_position)
	if trail_points.size() > max_trail_length:
		trail_points.pop_front()
	
	queue_redraw()

func _draw() -> void:
	if trail_points.size() < 2:
		return
	
	for i in range(trail_points.size() - 1):
		var alpha = float(i) / float(trail_points.size())
		var color = Color(1.0, 1.0, 1.0, alpha * 0.5)
		var start = to_local(trail_points[i])
		var end = to_local(trail_points[i + 1])
		draw_line(start, end, color, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if hit_enemies.has(body):
			return
		if "is_dying" in body and body.is_dying:
			return
		
		hit_enemies.append(body)
		body.TakeDamage(damage)
		
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
