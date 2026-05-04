extends AnimatedSprite2D

@export var totem_scene: PackedScene

var has_summoned: bool = false

func _ready() -> void:
	play("summon")
	frame_changed.connect(_on_frame_changed)
	animation_finished.connect(_on_animation_finished)

func _on_frame_changed() -> void:
	if frame == 5 and not has_summoned:
		spawn_enemies()
		has_summoned = true

func spawn_enemies() -> void:
	var current_scene = get_tree().root.get_node("Level")
	var num_enemies = randi_range(2, 4)
	
	for i in range(num_enemies):
		var enemy_type = randi() % 2
		var enemy
		
		if enemy_type == 0:
			enemy = totem_scene.instantiate()

		
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		enemy.global_position = global_position + offset
		current_scene.enemy_holder.add_child(enemy)
		current_scene.enemy_list.append(enemy)

func _on_animation_finished() -> void:
	queue_free()
