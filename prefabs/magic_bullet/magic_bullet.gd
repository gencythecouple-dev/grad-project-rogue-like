extends Area2D
class_name MagicBullet
@export var flight_speed := 300
var target: Area2D
var flight_direction: Vector2
var damage : float
var pierce_count: int = 0
var enemies_hit: Array = []
var is_crit: bool = false
const ENEMY_LAYER := 1 << 1
const ENV_LAYER   := 1 << 2
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	if has_meta("magic_level"):
		var level = get_meta("magic_level")
		if level >= 5:
			$AnimatedSprite2D.play("attack2")
		else:
			$AnimatedSprite2D.play("attack1")
	
	if has_meta("direction"):
		flight_direction = get_meta("direction")
		rotation = flight_direction.angle()
		return
	
	if target == null or !is_instance_valid(target):
		queue_free()
		return
	
	flight_direction = global_position.direction_to(target.global_position)
	
	if has_meta("angle_offset"):
		var angle_offset = get_meta("angle_offset")
		flight_direction = flight_direction.rotated(deg_to_rad(angle_offset))
	
	rotation = flight_direction.angle()

func _physics_process(delta: float) -> void:
	position += flight_direction * flight_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if enemies_hit.has(area):
			return
		
		enemies_hit.append(area)
		area.TakeDamage(damage, is_crit)
		
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
		
		if enemies_hit.size() > pierce_count:
			queue_free()
