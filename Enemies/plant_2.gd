extends EnemyBase

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	if sprite.material:
		sprite.material = sprite.material.duplicate()
	sprite.play("default")

func setup_enemy() -> void:
	speed = 60.0

func apply_flash(intensity: float) -> void:
	var material = sprite.material as ShaderMaterial
	if material:
		material.set_shader_parameter("flash_intensity", intensity)
