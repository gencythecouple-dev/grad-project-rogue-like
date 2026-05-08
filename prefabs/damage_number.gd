extends Node2D

@onready var label: Label = $Label
var velocity: Vector2 = Vector2(0, -50)
var lifetime: float = 0.0
var max_lifetime: float = 1.0

func setup(damage: float, spawn_position: Vector2, is_crit: bool = false) -> void:
	global_position = spawn_position
	label.text = str(int(damage))
	
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0, 1.0))
		label.scale = Vector2(1.5, 1.5)
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.scale = Vector2(1.0, 1.0)

func _physics_process(delta: float) -> void:
	lifetime += delta
	position += velocity * delta
	velocity.y += 100 * delta
	
	var alpha = 1.0 - (lifetime / max_lifetime)
	modulate.a = alpha
	
	if lifetime >= max_lifetime:
		queue_free()
