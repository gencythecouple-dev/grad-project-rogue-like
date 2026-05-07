extends AnimatedSprite2D

@export var totem_scene: PackedScene

func _ready() -> void:
	await get_tree().process_frame
	play("summon")
	
	animation_finished.connect(_on_animation_finished)	

func _on_animation_finished() -> void:
	spawn_totem()
	queue_free()

func spawn_totem() -> void:
	if totem_scene == null:
		return
	
	var current_scene = get_tree().root.get_node("Level")
	var necromancer = get_tree().get_first_node_in_group("Necromancer")
	
	var totem = totem_scene.instantiate()
	totem.global_position = global_position
	current_scene.enemy_holder.add_child(totem)
	current_scene.enemy_list.append(totem)
	
	if necromancer:
		necromancer.active_totems += 1
	
	totem.tree_exited.connect(func():
		if necromancer and is_instance_valid(necromancer):
			necromancer.active_totems -= 1
	)

func find_enemy_concentration_spots(scene, player, num_spots: int) -> Array:
	var all_enemies = get_tree().get_nodes_in_group("Enemy")
	var grid_size = 200.0
	var min_distance_from_player = 300.0
	var concentration_map = {}
	
	for enemy in all_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if "is_dying" in enemy and enemy.is_dying:
			continue
		
		var grid_x = int(enemy.global_position.x / grid_size)
		var grid_y = int(enemy.global_position.y / grid_size)
		var grid_key = Vector2i(grid_x, grid_y)
		
		if concentration_map.has(grid_key):
			concentration_map[grid_key] += 1
		else:
			concentration_map[grid_key] = 1
	
	var sorted_cells = []
	for cell in concentration_map:
		var cell_center = Vector2(cell.x * grid_size + grid_size/2, cell.y * grid_size + grid_size/2)
		var distance_to_player = cell_center.distance_to(player.global_position)
		
		if distance_to_player >= min_distance_from_player:
			sorted_cells.append({"pos": cell_center, "count": concentration_map[cell]})
	
	sorted_cells.sort_custom(func(a, b): return a["count"] > b["count"])
	
	var result = []
	for i in range(min(num_spots, sorted_cells.size())):
		result.append(sorted_cells[i]["pos"])
	
	if result.size() < num_spots:
		for i in range(num_spots - result.size()):
			var random_offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
			result.append(global_position + random_offset)
	
	return result
