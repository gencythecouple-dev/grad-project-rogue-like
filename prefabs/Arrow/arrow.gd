extends CharacterBody2D
class_name Arrow

@export var flight_speed := 300

var target: CharacterBody2D
var flight_direction: Vector2
var damage : float

const ENEMY_LAYER := 1 << 1
const ENV_LAYER   := 1 << 2


func _ready() -> void:
	if target == null or !is_instance_valid(target):
		queue_free()
		return

	flight_direction = global_position.direction_to(target.global_position)
	rotation = flight_direction.angle()


func _physics_process(delta: float) -> void:
	velocity = flight_direction * flight_speed
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body == null:
			continue
		var layer: int = body.collision_layer

		# ---- ENEMY ----
		if body.is_in_group("enemy"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
			queue_free()
			return

		# Hit wall / obstacle / environment
		if layer & ENV_LAYER:
			queue_free()
			return
			
func _on_hit_enemy():
	queue_free()
