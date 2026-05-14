extends Area2D

var damage: float = 5.0
var is_crit: bool = false

func _ready() -> void:
	monitoring = false
	$AnimatedSprite2D.play("grow")
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	$AnimatedSprite2D.frame_changed.connect(_on_frame_changed)
	area_entered.connect(_on_area_entered)

func setup(spike_damage: float, spike_scale: float, flipped: bool, spike_is_crit: bool = false) -> void:
	damage = spike_damage
	is_crit = spike_is_crit
	$AnimatedSprite2D.scale = Vector2(spike_scale, spike_scale)
	$CollisionShape2D.scale = Vector2(spike_scale, spike_scale)
	$AnimatedSprite2D.flip_h = flipped

func _on_frame_changed() -> void:
	if $AnimatedSprite2D.frame == 4:
		monitoring = true
	elif $AnimatedSprite2D.frame == 5:
		monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		area.TakeDamage(damage, is_crit)

func _on_animation_finished() -> void:
	queue_free()
