extends Area2D

var damage: float = 5.0

func _ready() -> void:
	$AnimatedSprite2D.play("grow")
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	body_entered.connect(_on_body_entered)

func setup(spike_damage: float, spike_scale: float, flipped: bool) -> void:
	damage = spike_damage
	$AnimatedSprite2D.scale = Vector2(spike_scale, spike_scale)
	$CollisionShape2D.scale = Vector2(spike_scale, spike_scale)
	$AnimatedSprite2D.flip_h = flipped

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.TakeDamage(damage)

func _on_animation_finished() -> void:
	queue_free()
