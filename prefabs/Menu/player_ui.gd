extends CanvasLayer

@onready var exp_bar = $"VBoxContainer/ExpBar"
@onready var level_label = $"VBoxContainer/HBoxContainer/LevelLabel"
@onready var timer_label = $"VBoxContainer/HBoxContainer/Label"
@onready var fps_label = $"VBoxContainer/FPS"
@onready var enemy_count_label = $"VBoxContainer/EnemyCount"
@onready var active_slots = [
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/ActiveItemsRow/ActiveSlot1/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/ActiveItemsRow/ActiveSlot2/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/ActiveItemsRow/ActiveSlot3/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/ActiveItemsRow/ActiveSlot4/TextureRect"
]
@onready var passive_slots = [
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/PassiveItemsRow/PassiveSlot1/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/PassiveItemsRow/PassiveSlot2/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/PassiveItemsRow/PassiveSlot3/TextureRect",
	$"VBoxContainer/HBoxContainer/ItemContainerDisplay/PassiveItemsRow/PassiveSlot4/TextureRect"
]

@onready var gold_label = $"VBoxContainer/HBoxContainer/Control2/GoldCount/GoldCount"
@onready var kill_label = $"VBoxContainer/HBoxContainer/Control2/KillCount/KillCount"

var active_count = 0
var passive_count = 0

func _ready():
	add_to_group("PlayerUI")
	if exp_bar:
		exp_bar.show_percentage = false
	
	for slot in active_slots + passive_slots:
		if slot:
			slot.modulate = Color(0.3, 0.3, 0.3, 0.5)

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if enemy_count_label:
		var level = get_tree().get_first_node_in_group("MainScene")
		if level:
			enemy_count_label.text = "Enemies: " + str(level.enemy_list.size())
	if gold_label:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			gold_label.text = str(player.run_gold)
	if kill_label:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			kill_label.text = str(player.total_kills)

func update_exp(current: int, needed: int):
	if exp_bar == null:
		return
	exp_bar.max_value = needed
	exp_bar.value = current

func update_level(level: int):
	if level_label == null:
		return
	level_label.text = "Level " + str(level)

func add_active_item(icon_texture: Texture2D):
	if active_count >= active_slots.size():
		return
	
	var slot = active_slots[active_count]
	if slot:
		slot.texture = icon_texture
		slot.modulate = Color.WHITE
		active_count += 1

func add_passive_item(icon_texture: Texture2D):
	if passive_count >= passive_slots.size():
		return
	
	var slot = passive_slots[passive_count]
	if slot:
		slot.texture = icon_texture
		slot.modulate = Color.WHITE
		passive_count += 1

func update_timer(time: float) -> void:
	var total_seconds: int = int(time)
	var minutes: int = floor(total_seconds / 60.0)
	var seconds: int = total_seconds - (minutes * 60)
	var time_string: String = "%02d:%02d" % [minutes, seconds]
	timer_label.text = time_string
