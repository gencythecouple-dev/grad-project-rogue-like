extends CharacterBody2D

const SPEED := 230.0

@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var player := get_tree().get_first_node_in_group("player")

func _ready() -> void:
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0

func _physics_process(delta: float) -> void:
	if player == null:
		return

	agent.target_position = player.global_position

	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_pos := agent.get_next_path_position()
		var direction := (next_pos - global_position).normalized()
		velocity = direction * SPEED

	move_and_slide()
