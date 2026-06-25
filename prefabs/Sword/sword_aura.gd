extends Area2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var damage: float = 10.0
var player: CharacterBody2D
var is_crit: bool = false

func _ready() -> void:
	monitoring = true
	sprite.play("default")
	sprite.frame_changed.connect(_on_frame_changed)
	AudioManager.play_sword_aura()

func setup(spawn_player: CharacterBody2D, spawn_damage: float) -> void:
	player = spawn_player
	damage = spawn_damage

func _on_frame_changed() -> void:
	if sprite.frame != 6:
		return
	for area in get_overlapping_areas():
		if area.is_in_group("Enemy"):
			if "is_dying" in area and area.is_dying:
				continue
			area.TakeDamage(damage, is_crit)
			if player:
				player.total_damage_dealt += damage
		elif area.get_parent().is_in_group("Obstacle"):
			area.get_parent().take_damage()
