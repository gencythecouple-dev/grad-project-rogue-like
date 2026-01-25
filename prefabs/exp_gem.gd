extends Area2D
class_name ExperienceGem

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var exp_value: int = 1
@export var move_speed: float = 300.0

var player_ref = null
var is_collected := false
var chase_timer: float = 0.0  # Track how long we've been chasing
var speed_boosted: bool = false

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")	
	monitoring = true
	monitorable = true
	
	collision_layer = 1
	collision_mask = 5
	
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play("default")

func setup(exp_amount: int, animation_name: String = "default"):
	exp_value = exp_amount
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)

func _physics_process(delta: float) -> void:
	if is_collected or player_ref == null:
		return
	
	var distance = global_position.distance_to(player_ref.global_position)
	
	if distance < 100:
		chase_timer += delta
		
		# Speed boost after 0.5 seconds of chasing
		if chase_timer >= 0.5 and not speed_boosted:
			speed_boosted = true
			move_speed *= 2.0  # Double the speed
		
		var direction = global_position.direction_to(player_ref.global_position)
		global_position += direction * move_speed * delta
	else:
		# Reset timer if player moves away
		chase_timer = 0.0
		speed_boosted = false
		move_speed = 300.0  # Reset to base speed

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_collected:
		is_collected = true
		if body.has_method("CollectExperience"):
			body.CollectExperience(exp_value)
		queue_free()
