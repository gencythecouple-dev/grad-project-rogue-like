extends CharacterBody2D

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_cooldown: Timer = $AttackCooldown

@onready var run_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Run.png")
@onready var attack_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Red Units/Warrior/Warrior_Attack1.png")

const SPEED := 150
const ATTACK_RANGE := 75


var player_ref
var current_state: STATE
var player_in_range := false
var can_attack := true

enum STATE {
	RUN,
	ATTACK
}

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	attack_cooldown.one_shot = true
	current_state = STATE.RUN
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

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
	if current_state == STATE.RUN and attack_cooldown.is_stopped() and is_player_in_attack_range():
		ChangeState(STATE.ATTACK)

	move_and_slide()


func ChangeState(new_state: STATE) -> void:
	current_state = new_state

	if new_state == STATE.RUN:
		sprite.texture = run_sheet
		anim_player.play("run")

	elif new_state == STATE.ATTACK:
		sprite.texture = attack_sheet
		anim_player.play("attack")

		attack_cooldown.start()
func is_player_in_attack_range() -> bool:
	if player_ref == null:
		return false
	return global_position.distance_to(player_ref.global_position) <= ATTACK_RANGE

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_range = false

func _on_attack_cooldown_timeout() -> void:
	if player_in_range and current_state == STATE.RUN:
		ChangeState(STATE.ATTACK)
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		ChangeState(STATE.RUN)
		attack_cooldown.start()
