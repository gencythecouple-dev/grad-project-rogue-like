extends Area2D

@export var shockwave_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $Timer

var damage: float = 10.0
var player: CharacterBody2D
var hammer_level: int = 1

func _ready() -> void:
	monitoring = false
	lifetime_timer.wait_time = 1.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	lifetime_timer.start()

func _on_frame_changed() -> void:
	if sprite.frame == 8:
		monitoring = true
		_spawn_shockwave()
	elif sprite.frame == 9:
		monitoring = false
		
func _spawn_shockwave() -> void:
	print("spawning shockwave at hammer_level: ", hammer_level)
	var spike_count = 1
	var shockwave_scale = 1.0
	var shockwave_spacing = 100

	match hammer_level:
		1: 
			spike_count = 1
		2:
			spike_count = 1
			shockwave_scale = 1.0
		3:
			spike_count = 2
			shockwave_scale = 1.5
		4:
			spike_count = 3
			shockwave_scale = 2.0
		5:
			spike_count = 3
			shockwave_scale = 2.5

	var direction = Vector2(1, 0) if !sprite.flip_h else Vector2(-1, 0)

	for i in range(spike_count):
		var shockwave = shockwave_scene.instantiate()
		var offset = direction * (shockwave_spacing * (i + 1))
		shockwave.global_position = global_position + offset
		get_tree().root.get_child(0).get_node("ShockwaveHolder").add_child(shockwave)
		shockwave.setup(damage * 0.5, shockwave_scale, sprite.flip_h)
		
func setup(spawn_player: CharacterBody2D, spawn_damage: float, level: int, scale_mult: float) -> void:
	player = spawn_player
	damage = spawn_damage
	hammer_level = level
	sprite.scale = Vector2(scale_mult, scale_mult)
	sprite.flip_h = !spawn_player.facing_right
	sprite.play("swing")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.TakeDamage(damage)

func _on_animation_finished() -> void:
	hide()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
