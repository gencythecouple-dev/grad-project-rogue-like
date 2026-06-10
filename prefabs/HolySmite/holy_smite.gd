extends Area2D
class_name HolySmite


var target_position: Vector2


var damage: float = 15.0
var has_hit: bool = false
var is_crit: bool = false

func setup(pos: Vector2) -> void:
	target_position = pos

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	global_position = target_position
	monitoring = false
	set_deferred("monitoring", true)
	area_entered.connect(_on_area_entered)
	AudioManager.play_holy_smite()
	$AnimatedSprite2D.play("strike")
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_frame_changed() -> void:
	if $AnimatedSprite2D.frame == 3 and not has_hit:
		_strike()

func _strike() -> void:
	var overlapping = get_overlapping_areas()
	for area in overlapping:
		if area.is_in_group("Enemy") and not has_hit:
			if "is_dying" in area and area.is_dying:
				continue
			area.TakeDamage(damage, is_crit)
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				player.total_damage_dealt += damage
			has_hit = true
			break

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy") and not has_hit:
		if "is_dying" in area and area.is_dying:
			return
		area.TakeDamage(damage, is_crit)
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			player.total_damage_dealt += damage
		has_hit = true

func _on_animation_finished() -> void:
	queue_free()
