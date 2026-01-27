extends CharacterBody2D
class_name Arrow

@export var flight_speed := 300

var target: CharacterBody2D
var flight_direction: Vector2
var damage : float

const ENEMY_LAYER := 1 << 1
const ENV_LAYER   := 1 << 2


func _ready() -> void:
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
	velocity = flight_direction * flight_speed
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body == null:
			continue

		# --- Hit enemy ---
		# In the collision handling
		if body is CharacterBody2D and body.has_method("_on_hurt"):
			body._on_hurt(damage)
			queue_free()
			return

		# --- Hit environment (TileMapLayer) ---
		if body is TileMapLayer:
			queue_free()
			return

func _on_hit_enemy():
	queue_free()
