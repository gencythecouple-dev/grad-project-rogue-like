extends Area2D
class_name Knife

@export var flight_speed := 350
var flight_direction: Vector2
var damage: float

func _ready() -> void:
	if has_meta("direction"):
		flight_direction = get_meta("direction")
		rotation = flight_direction.angle()
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += flight_direction * flight_speed * delta

func _on_body_entered(body: Node2D) -> void:
	print("🔪 Knife hit something: ", body.name)
	
	if body.is_in_group("Enemy"):
		print("✅ It's an enemy!")
		print("   Damage value: ", damage)
		print("   Enemy is_dying: ", body.is_dying if "is_dying" in body else "NO FLAG")
		
		if "is_dying" in body and body.is_dying:
			print("❌ Enemy already dying, passing through")
			return
		
		print("💥 Calling TakeDamage(", damage, ")")
		body.TakeDamage(damage)
		
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
		
		queue_free()
