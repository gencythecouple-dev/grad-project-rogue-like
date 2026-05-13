extends Area2D
class_name Knife

@export var flight_speed := 350
var flight_direction: Vector2
var damage: float
var is_crit: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if has_meta("direction"):
		flight_direction = get_meta("direction")
		rotation = flight_direction.angle()

func _physics_process(delta: float) -> void:
	position += flight_direction * flight_speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		if "is_dying" in area and area.is_dying:
			return
		
		area.TakeDamage(damage, is_crit)
		
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
		
		queue_free()
