extends Area2D
class_name HolySmite

var damage: float = 15.0
var has_hit: bool = false

func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	
	$AnimatedSprite2D.play("strike")
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	
	await get_tree().create_timer(0.2).timeout
	monitoring = true
	_strike()
	
	await get_tree().create_timer(0.1).timeout
	monitoring = false

func _strike() -> void:
	var overlapping = get_overlapping_bodies()
	for body in overlapping:
		if body.is_in_group("Enemy") and not has_hit:
			if "is_dying" in body and body.is_dying:
				continue
			body.TakeDamage(damage)
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				player.total_damage_dealt += damage
			has_hit = true
			break

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy") and not has_hit:
		if "is_dying" in body and body.is_dying:
			return
		body.TakeDamage(damage)
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
		has_hit = true

func _on_animation_finished() -> void:
	queue_free()
