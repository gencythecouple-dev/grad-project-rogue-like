extends Area2D
class_name StarProjectile

@export var explosion_scene: PackedScene

const BOUNCE_COOLDOWN_TIME: float = 0.3
const MIN_ANGLE_COMPONENT: float = 0.3


var bounce_cooldown: float = 0.0

var speed: float = 300.0
var damage: float = 3.0
var star_level: int = 1
var velocity: Vector2
var hit_enemies: Array = []
var lifetime: float = 0.0
var max_lifetime: float = 10.0
var trail_points: Array = []
var max_trail_length: int = 60
var is_crit: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	$AnimatedSprite2D.play("default")
	AudioManager.play_star()
	var random_angle = randf() * TAU
	velocity = Vector2(cos(random_angle), sin(random_angle)) * speed

func _enforce_min_angle() -> void:
	if abs(velocity.x) < speed * MIN_ANGLE_COMPONENT:
		velocity.x = speed * MIN_ANGLE_COMPONENT * (1.0 if velocity.x >= 0 else -1.0)
	if abs(velocity.y) < speed * MIN_ANGLE_COMPONENT:
		velocity.y = speed * MIN_ANGLE_COMPONENT * (1.0 if velocity.y >= 0 else -1.0)
	velocity = velocity.normalized() * speed


func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	if bounce_cooldown > 0:
		bounce_cooldown -= delta
	global_position += velocity * delta
	for area in get_overlapping_areas():
		if area.get_parent().is_in_group("Obstacle"):
			area.get_parent().take_damage()
			break
	
	var viewport_rect = get_viewport_rect()
	var cam = get_viewport().get_camera_2d()
	if cam:
		var cam_pos = cam.global_position
		var half_size = viewport_rect.size / (2.0 * cam.zoom)
		var margin := 20.0
		var left: float = cam_pos.x - half_size.x + margin
		var right: float = cam_pos.x + half_size.x - margin
		var top: float = cam_pos.y - half_size.y + margin
		var bottom: float = cam_pos.y + half_size.y - margin
		
		if global_position.x <= left:
			velocity.x = abs(velocity.x)
			global_position.x = left + 1.0
			_enforce_min_angle()
			_try_spawn_explosion()
		elif global_position.x >= right:
			velocity.x = -abs(velocity.x)
			global_position.x = right - 1.0
			_enforce_min_angle()
			_try_spawn_explosion()
		
		if global_position.y <= top:
			velocity.y = abs(velocity.y)
			global_position.y = top + 1.0
			_enforce_min_angle()
			_try_spawn_explosion()
		elif global_position.y >= bottom:
			velocity.y = -abs(velocity.y)
			global_position.y = bottom - 1.0
			_enforce_min_angle()
			_try_spawn_explosion()
	
	trail_points.append(global_position)
	if trail_points.size() > max_trail_length:
		trail_points.pop_front()
	queue_redraw()

func _try_spawn_explosion() -> void:
	if bounce_cooldown > 0:
		return
	bounce_cooldown = BOUNCE_COOLDOWN_TIME
	_spawn_explosion()
	
func _draw() -> void:
	if trail_points.size() < 2:
		return
	
	for i in range(trail_points.size() - 1):
		var alpha = float(i) / float(trail_points.size())
		var color = Color(1.0, 1.0, 1.0, alpha * 0.5)
		var start = to_local(trail_points[i])
		var end = to_local(trail_points[i + 1])
		draw_line(start, end, color, 2.0)

func _spawn_explosion() -> void:
	if explosion_scene == null or star_level < 5:
		return
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().root.get_node("Level").add_child(explosion)
	explosion.setup(damage, is_crit)

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("Obstacle"):
		area.get_parent().take_damage()
		return
	if area.is_in_group("Enemy"):
		if hit_enemies.has(area):
			return
		if "is_dying" in area and area.is_dying:
			return
		hit_enemies.append(area)
		area.TakeDamage(damage, is_crit)
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
