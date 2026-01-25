extends Node2D

@onready var label: Label = $Label

var velocity := Vector2(0, -50)
var lifetime := 0.6
var fade_start := 0.3

func _ready() -> void:
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

func setup(damage_value: float, pos: Vector2):
	global_position = pos
	label.text = str(int(damage_value))
	
	velocity.x = randf_range(-20, 20)

func _process(delta: float) -> void:
	lifetime -= delta
	
	global_position += velocity * delta
	
	if lifetime < fade_start:
		label.modulate.a = lifetime / fade_start
	
	if lifetime <= 0:
		queue_free()
