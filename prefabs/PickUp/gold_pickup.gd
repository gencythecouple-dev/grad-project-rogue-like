extends Area2D
class_name GoldPickup

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var move_speed: float = 300.0

var gold_value: int = 5
var player_ref = null
var is_collected := false
var chase_timer: float = 0.0
var speed_boosted: bool = false

const CULL_DISTANCE: float = 800.0

func _ready() -> void:
	add_to_group("GoldPickup")
	player_ref = get_tree().get_first_node_in_group("Player")
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	collision_layer = 1
	collision_mask = 5

func setup(amount: int, animation_name: String = "coin") -> void:
	print("setup called - amount: ", amount, " animation: ", animation_name)
	gold_value = amount
	print("has animation: ", animated_sprite.sprite_frames.has_animation(animation_name))
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
		else:
			print("animation not found: ", animation_name)
	is_collected = false
	chase_timer = 0.0
	speed_boosted = false
	move_speed = 300.0
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)

func _physics_process(delta: float) -> void:
	if is_collected or player_ref == null:
		return
	var distance := global_position.distance_to(player_ref.global_position)
	if distance > CULL_DISTANCE:
		return
	var pickup_range: float = player_ref.magnet_range if "magnet_range" in player_ref else 100.0
	if distance < pickup_range:
		chase_timer += delta
		if chase_timer >= 0.5 and not speed_boosted:
			speed_boosted = true
			move_speed *= 2.0
		var direction := global_position.direction_to(player_ref.global_position)
		global_position += direction * move_speed * delta
	else:
		chase_timer = 0.0
		speed_boosted = false
		move_speed = 300.0

func _start_chase() -> void:
	speed_boosted = true
	move_speed *= 2.0
	chase_timer = 999.0

func _on_body_entered(body: Node2D) -> void:
	AudioManager.play_gold_pick_up()
	if body.is_in_group("Player") and not is_collected:
		is_collected = true
		if "run_gold" in body:
			body.run_gold += gold_value
		queue_free()
