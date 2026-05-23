extends Node2D

@onready var gold_label: Label = $CanvasLayer/CenterContainer/PanelContainer/VBoxContainer/Gold
@onready var grid: GridContainer = $CanvasLayer/CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var close_button: Button = $CanvasLayer/Close
@onready var title_label: Label = $CanvasLayer/CenterContainer/PanelContainer/VBoxContainer/Tittle

const upgrades := [
	{
		"id": "might",
		"name": "Might",
		"description": "+10% Damage on all weapons",
		"icon": preload("res://Assets/Upgrades/attk_up.png")
	},
	{
		"id": "max_hp",
		"name": "Fortitude",
		"description": "+50 Max HP",
		"icon": preload("res://Assets/Upgrades/HP_up.png")
	},
	{
		"id": "armor",
		"name": "Iron Skin",
		"description": "+1 Armor",
		"icon": preload("res://Assets/Upgrades/26.png")
	},
	{
		"id": "move_speed",
		"name": "Swiftness",
		"description": "+3% Movement Speed",
		"icon": preload("res://Assets/Upgrades/move_spd.png")
	},
	{
		"id": "attack_speed",
		"name": "Alacrity",
		"description": "+3% Attack Speed",
		"icon": preload("res://Assets/Upgrades/attk_spd.png")
	},
	{
		"id": "recovery",
		"name": "Recovery",
		"description": "+0.5 HP regen per second",
		"icon": preload("res://Assets/Upgrades/HP_up.png")
	},
	{
		"id": "magnet",
		"name": "Magnet",
		"description": "+50px Pickup Range",
		"icon": preload("res://Assets/Upgrades/magnet.jpg")
	},
	{
		"id": "greed",
		"name": "Greed",
		"description": "+5% Gold and EXP gain",
		"icon": preload("res://Assets/Upgrades/greed.png")
	},
	{
		"id": "crit",
		"name": "Precision",
		"description": "+2% Crit Chance",
		"icon": preload("res://Assets/Upgrades/crit.png")
	},
	{
		"id": "revivals",
		"name": "Second Chance",
		"description": "Revive once per run with 25% HP",
		"icon": preload("res://Assets/Upgrades/HP_up.png")
	},
	{
		"id": "curse",
		"name": "Curse",
		"description": "+10% more enemies, +10% Gold and EXP",
		"icon": preload("res://Assets/Upgrades/greed.png")
	},
]

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_grid()
	_update_gold()

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	title_label.add_theme_color_override("font_color", Color.from_hsv(fmod(t * 0.3, 1.0), 1.0, 1.0))

func _update_gold() -> void:
	gold_label.text = "Gold: " + str(GameData.gold)

func _build_grid() -> void:
	for child in grid.get_children():
		child.queue_free()

	for upgrade in upgrades:
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		var icon := TextureRect.new()
		var name_label := Label.new()
		var desc_label := Label.new()
		var level_label := Label.new()
		var buy_button := Button.new()

		icon.texture = upgrade["icon"]
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

		name_label.text = upgrade["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		desc_label.text = upgrade["description"]
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var max_level: int = GameData.UPGRADE_MAX_LEVELS[upgrade["id"]]
		var current_level: int = GameData.meta_upgrades[upgrade["id"]]
		level_label.text = "Level " + str(current_level) + "/" + str(max_level)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var cost := GameData.get_upgrade_cost(upgrade["id"])
		if GameData.is_maxed(upgrade["id"]):
			buy_button.text = "MAXED"
			buy_button.disabled = true
		else:
			buy_button.text = "Buy (" + str(cost) + "g)"
			buy_button.disabled = false
		buy_button.pressed.connect(_on_buy_pressed.bind(upgrade["id"], buy_button, level_label))

		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

		vbox.add_child(icon)
		vbox.add_child(name_label)
		vbox.add_child(desc_label)
		vbox.add_child(level_label)
		vbox.add_child(spacer)
		vbox.add_child(buy_button)
		panel.add_child(vbox)
		panel.custom_minimum_size = Vector2(200, 180)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)

func _on_buy_pressed(id: String, buy_button: Button, level_label: Label) -> void:
	var cost := GameData.get_upgrade_cost(id)
	if GameData.buy_upgrade(id, cost):
		var max_level: int = GameData.UPGRADE_MAX_LEVELS[id]
		var current_level: int = GameData.meta_upgrades[id]
		level_label.text = "Level " + str(current_level) + "/" + str(max_level)
		if GameData.is_maxed(id):
			buy_button.text = "MAXED"
			buy_button.disabled = true
		else:
			var new_cost := GameData.get_upgrade_cost(id)
			buy_button.text = "Buy (" + str(new_cost) + "g)"
		_update_gold()

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
