extends Area2D
class_name PowerUpPickup

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_ref = null
var is_collected := false

const CULL_DISTANCE: float = 800.0
const BOOST_DURATION: float = 15.0
const DAMAGE_BOOST: float = 1.25
const SPEED_BOOST: float = 1.20
const ARMOR_BOOST: float = 1.15

func _ready() -> void:
	player_ref = get_tree().get_first_node_in_group("Player")
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	collision_layer = 1
	collision_mask = 5
	body_entered.connect(_on_body_entered)
	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play("default")

func _physics_process(_delta: float) -> void:
	if is_collected or player_ref == null:
		return
	var distance := global_position.distance_to(player_ref.global_position)
	if distance > CULL_DISTANCE:
		return
	var pickup_range: float = player_ref.magnet_range if "magnet_range" in player_ref else 100.0
	if distance < pickup_range:
		var direction := global_position.direction_to(player_ref.global_position)
		global_position += direction * 300.0 * get_physics_process_delta_time()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_collected:
		is_collected = true
		AudioManager.play_damage_up()
		_apply_boost(body)
		queue_free()

func _apply_boost(player: Node) -> void:
	player.base_attack *= DAMAGE_BOOST
	player.SPEED *= SPEED_BOOST
	player.base_armor *= ARMOR_BOOST
	player.current_armor = player.base_armor
	player.rainbow_active = true
	get_tree().create_timer(BOOST_DURATION).timeout.connect(func():
		player.base_attack /= DAMAGE_BOOST
		player.SPEED /= SPEED_BOOST
		player.base_armor /= ARMOR_BOOST
		player.current_armor = player.base_armor
		player.rainbow_active = false
		var mat = player.sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("rainbow_active", false)
	)
