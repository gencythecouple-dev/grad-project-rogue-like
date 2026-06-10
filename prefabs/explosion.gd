extends Area2D

var damage: float = 0.0
var is_crit: bool = false

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	$AnimatedSprite2D.animation_finished.connect(queue_free)
	AudioManager.play_explosion()
	await get_tree().physics_frame
	_burst()

func _burst() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("Enemy"):
			if "is_dying" in area and area.is_dying:
				continue
			area.TakeDamage(damage, is_crit)
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				player.total_damage_dealt += damage

func setup(star_damage: float, star_is_crit: bool) -> void:
	damage = star_damage * 2.0
	is_crit = star_is_crit
