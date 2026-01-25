extends Node2D

@onready var label: Label = $Label

var velocity := Vector2(0, -50)  # Float upward
var lifetime := 0.6  # How long it lasts
var fade_start := 0.3  # When to start fading

func _ready() -> void:
	# Configure label appearance
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

func setup(damage_value: float, pos: Vector2):
	global_position = pos
	label.text = str(int(damage_value))
	
	# Randomize horizontal movement slightly
	velocity.x = randf_range(-20, 20)

func _process(delta: float) -> void:
	lifetime -= delta
	
	# Move upward
	global_position += velocity * delta
	
	# Fade out
	if lifetime < fade_start:
		label.modulate.a = lifetime / fade_start
	
	# Remove when done
	if lifetime <= 0:
		queue_free()
