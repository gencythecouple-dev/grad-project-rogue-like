extends CharacterBody2D

const SPEED := 250

@onready var run_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Run.png")
@onready var idle_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Idle.png")
@onready var attack_sheet = load("res://Assets/Tiny Swords (Free Pack)/Tiny Swords (Free Pack)/Units/Yellow Units/Archer/Archer_Shoot.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@export var arrow_scene: PackedScene

var current_scene: Node2D


var direction := Vector2.ZERO
var facing_right := true
var attacking := false


func _ready() -> void:
	add_to_group("Player")
	current_scene = get_tree().get_first_node_in_group("MainScene")
	attack_timer.start()

func _physics_process(delta: float) -> void:
	direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if attacking:
		animate_player()
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	update_facing()
	animate_player()
	move_and_slide()


func update_facing():
	if direction.x != 0:
		facing_right = direction.x > 0

	sprite.flip_h = !facing_right

func animate_player():
	if attacking:
		return

	if direction == Vector2.ZERO:
		if anim_player.current_animation != "idle":
			sprite.texture = idle_sheet
			anim_player.play("idle")
	else:
		if anim_player.current_animation != "run":
			sprite.texture = run_sheet
			anim_player.play("run")



# ------------------------
# ATTACK LOGIC
# ------------------------

func start_attack():
	if attacking:
		return

	attacking = true
	sprite.texture = attack_sheet
	sprite.hframes = 8
	sprite.frame = 0
	anim_player.play("attack")





func Attack():
	var new_arrow: Arrow = arrow_scene.instantiate()
	var closest_distance := 5000.0
	var target_enemy = null

	for enemy in current_scene.enemy_list:
		var dist: float = enemy.position.distance_to(position)
		if dist < closest_distance:
			closest_distance = dist
			target_enemy = enemy

	if target_enemy == null:
		return

	new_arrow.target = target_enemy
	new_arrow.position = position
	current_scene.arrow_holder.add_child(new_arrow)


func end_attack():
	attacking = false



func _on_attack_timer_timeout() -> void:
	start_attack()
