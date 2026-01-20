extends CharacterBody2D

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@onready var run_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Run.png")
@onready var attack_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Attack1.png")

var player_ref
var current_state : STATE


const SPEED := 150

enum STATE {
	RUN,
	ATTACK
}

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	current_state = STATE.ATTACK # force first transition
	ChangeState(STATE.RUN)

func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	if current_state == STATE.RUN:
		nav_agent.target_position = player_ref.global_position

		if not nav_agent.is_navigation_finished():
			var next_pos := nav_agent.get_next_path_position()
			velocity = global_position.direction_to(next_pos) * SPEED
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func ChangeState(new_state: STATE) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	if new_state == STATE.RUN:
		sprite.texture = run_sheet
		anim_player.play("run")
	elif new_state == STATE.ATTACK:
		sprite.texture = attack_sheet
		anim_player.play("attack")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and current_state == STATE.RUN:
		ChangeState(STATE.ATTACK)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		ChangeState(STATE.RUN)


func _on_timer_timeout() -> void:
	current_state == STATE.RUN
