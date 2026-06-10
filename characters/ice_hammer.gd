extends Area2D

@export var shockwave_scene: PackedScene
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime_timer: Timer = $Timer

var damage: float = 10.0
var player: CharacterBody2D
var hammer_level: int = 1
var is_crit: bool = false

func _ready() -> void:
	monitoring = false
	lifetime_timer.wait_time = 1.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_timer_timeout)
	area_entered.connect(_on_area_entered)
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
	var crit_result = player.get_crit_damage(damage * 0.5)
	var direction = Vector2(1, 0) if !sprite.flip_h else Vector2(-1, 0)
	
	for i in range(spike_count):
		var shockwave = shockwave_scene.instantiate()
		var offset = direction * (shockwave_spacing * (i + 1))
		shockwave.global_position = global_position + offset
		shockwave.setup(crit_result["damage"], shockwave_scale, sprite.flip_h, crit_result["is_crit"])
		get_tree().root.get_node("Level").get_node("ShockwaveHolder").add_child(shockwave)
		AudioManager.play_hammer_spike()

func setup(spawn_player: CharacterBody2D, spawn_damage: float, level: int, scale_mult: float) -> void:
	player = spawn_player
	damage = spawn_damage
	hammer_level = level
	
	var anim_sprite = $AnimatedSprite2D
	anim_sprite.scale = Vector2(scale_mult, scale_mult)
	anim_sprite.flip_h = !spawn_player.facing_right
	anim_sprite.play("swing")
	AudioManager.play_hammer_swing()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		area.TakeDamage(damage, is_crit)
		player.total_damage_dealt += damage

func _on_animation_finished() -> void:
	hide()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
