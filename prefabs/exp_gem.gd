extends Area2D
class_name ExperienceGem

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var exp_value: int = 1
@export var move_speed: float = 300.0

var player_ref = null
var is_collected := false

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	print("Gem created! Player ref: ", player_ref)
	
	monitoring = true
	monitorable = true
	
	collision_layer = 16  # Layer 5 for gems
	collision_mask = 255  # Detect ALL layers (for debugging)
	
	print("Gem collision setup - monitoring: ", monitoring, " mask: ", collision_mask)
	
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
		var direction = global_position.direction_to(player_ref.global_position)
		global_position += direction * move_speed * delta

func _on_body_entered(body: Node2D) -> void:
	print("!!! GEM HIT: ", body.name, " Type: ", body.get_class(), " !!!")
	if body.is_in_group("Player") and not is_collected:
		is_collected = true
		print("💎 COLLECTING GEM!")
		if body.has_method("CollectExperience"):
			body.CollectExperience(exp_value)
		queue_free()
