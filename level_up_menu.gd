
extends CanvasLayer
signal upgrade_selected(upgrade_type: String)

@onready var choice1: Button = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice1
@onready var choice2: Button = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice2
@onready var choice3: Button = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice3

@onready var choice1_label: Label = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice1/NinePatchRect/Label
@onready var choice2_label: Label = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice2/NinePatchRect/Label
@onready var choice3_label: Label = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice3/NinePatchRect/Label

@onready var choice1_icon: TextureRect = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice1/TextureRect
@onready var choice2_icon: TextureRect = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice2/TextureRect
@onready var choice3_icon: TextureRect = $ColorRect/CenterContainer/NinePatchRect/VBoxContainer/UpgradeChoice3/TextureRect

var active_upgrades_taken := 0
var passive_upgrades_taken := 0
const MAX_ACTIVE := 4
const MAX_PASSIVE := 4

var selected_index: int = 0
var buttons: Array = []

var all_upgrades := [
	#{
		#"name": "Increase Attack", 
		#"description": "+1 Attack Damage", 
		#"stat": "attack", 
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/attk_up.png"),
		#"upgrade_type": "passive"  
	#},
	#{
		#"name": "Increase Max HP", 
		#"description": "+10 Max Health", 
		#"stat": "max_hp", 
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/HP_up.png"),
		#"upgrade_type": "passive"  
	#},
	#{
		#"name": "Attack Speed", 
		#"description": "+15% Faster Attacks", 
		#"stat": "attack_speed", 
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/attk_spd.png"),
		#"upgrade_type": "passive"  
	#},
	#{
		#"name": "Movement Speed", 
		#"description": "+5% Move Speed", 
		#"stat": "move_speed", 
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/move_spd.png"),
		#"upgrade_type": "passive" 
	#},
	#{
		#"name": "Dupplicator", 
		#"description": "+1 to ALL projectiles", 
		#"stat": "more_projectile", 
		#"max_level": 3,
		#"icon": preload("res://Assets/Upgrades/duplicator.png"),
		#"upgrade_type": "passive"  
	#},			
	#{
		#"name": "Glacial Maul",
		#"stat": "ice_hammer",
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/ice_hammer.png"),
		#"upgrade_type": "active",
		#"requires": "",
		#"level_descriptions": {
			#1: "Crush enemies with a heavy frontal strike",
			#2: "+2 Damage",
			#3: "Bigger Spikes",
			#4: "Faster Cooldown",
			#5: "ALL: +Damage, Bigger, Faster + Ice Shockwave!"
		#},
		#},
		#{
		#"name": "Iron Shield",
		#"description": "Reduce incoming damage",
		#"stat": "armor",
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/26.png"),
		#"upgrade_type": "passive",
		#"requires": ""
	#},
	#{
		#"name": "Mystic Orb",
		#"description": "Fire magical projectiles at nearby enemies",
		#"stat": "magic_bullet",
		#"max_level": 5,
		#"icon": preload("res://Assets/magic_bullet.png"),
		#"upgrade_type": "active",
		#"requires": ""
	#},
	#{
		#"name": "Phantom Edge",
		#"description": "Throw knives in your movement direction",
		#"stat": "knife",
		#"max_level": 5,
		#"icon": preload("res://Assets/knife_icon.png"),
		#"upgrade_type": "active",
		#"requires": ""
	#},
	#{
		#"name": "Divine Wrath",
		#"description": "Strike a random enemy from above",
		#"stat": "holy_smite",
		#"max_level": 5,
		#"icon": preload("res://Assets/Holy Smite/holysmite.png"),
		#"upgrade_type": "active",
		#"requires" : ""
	#},
	#{
		#"name": "Crimson Edge",
		#"description": "Slash enemies in front of you",
		#"stat": "sword",
		#"max_level": 5,
		#"icon": preload("res://Assets/Sword/sword.png"),
		#"upgrade_type": "active",
		#"requires" : ""
	#},
	#{
		#"name": "Wind Shuriken",
		#"description": "Throw spinning blades that return to you",
		#"stat": "wind_shuriken",
		#"max_level": 5,
		#"icon": preload("res://Assets/Wind Shuriken/wind_shuriken.png"),
		#"upgrade_type": "active",
		#"requires": ""
	#},
	#{
		#"name": "Starfall",
		#"description": "Bouncing stars that ricochet across the screen",
		#"stat": "star",
		#"max_level": 5,
		#"icon": preload("res://Assets/Bouncy thing/Star.png"),
		#"upgrade_type": "active",
		#"requires": ""
	#},
	{
		"name": "Magnet",
		"description": "+20% Pickup Range",
		"stat": "magnet",
		"max_level": 5,
		"icon": preload("res://Assets/Upgrades/magnet.jpg"),
		"upgrade_type": "passive"
	},
	#{
		#"name": "Cursed book of knowledge",
		#"description": "+10% Experience Gain",
		#"stat": "greed",
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/greed.png"),
		#"upgrade_type": "passive"
	#},
	#{
		#"name": "Critical Strike",
		#"description": "+5% Crit Chance (2x Damage)",
		#"stat": "crit",
		#"max_level": 5,
		#"icon": preload("res://Assets/Upgrades/crit.png"),
		#"upgrade_type": "passive"
	#},
	#{
		#"name": "Vampirism",
		#"description": "Heal 1 HP per kill",
		#"stat": "vampirism",
		#"max_level": 3,
		#"icon": preload("res://Assets/Upgrades/vampirism.png"),
		#"upgrade_type": "passive"
	#},
	{
		"name": "Thunder Orb",
		"description": "A bouncing ball of lightning that leaps between enemies",
		"stat": "lightning_ball",
		"max_level": 5,
		"icon": preload("res://Assets/lightningball.png"),
		"upgrade_type": "active",
		"requires": "",
		"level_descriptions": {
			1: "Launch a lightning ball that bounces twice",
			2: "+1 Ball, +1 Bounce — balls target different enemies (2 balls, 3 bounces)",
			3: "+2 Bounces, +50% Damage (2 balls, 5 bounces)",
			4: "+1 Ball, +Damage (3 balls, 5 bounces)",
			5: "+2 Balls, +Damage , first hit triggers 3 seconds of infinite bouncing at double speed!"
		}
	},
]

var upgrade_levels := {}
var current_choices := []

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	buttons = [choice1, choice2, choice3]
	
	for upgrade in all_upgrades:
		upgrade_levels[upgrade["stat"]] = 0
	
	choice1.pressed.connect(_on_choice1_pressed)
	choice2.pressed.connect(_on_choice2_pressed)
	choice3.pressed.connect(_on_choice3_pressed)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		selected_index = (selected_index + 1) % current_choices.size()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		selected_index = (selected_index - 1 + current_choices.size()) % current_choices.size()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_apply_upgrade(selected_index)
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	for i in range(buttons.size()):
		if i < current_choices.size():
			var arrow_left = buttons[i].get_node_or_null("ArrowLeft")
			var arrow_right = buttons[i].get_node_or_null("ArrowRight")
			if i == selected_index:
				if arrow_left: arrow_left.show()
				if arrow_right: arrow_right.show()
			else:
				if arrow_left: arrow_left.hide()
				if arrow_right: arrow_right.hide()

func show_upgrades():
	var player = get_tree().get_first_node_in_group("Player")
	var owned_upgrades = []
	var new_upgrades = []
	
	for upgrade in all_upgrades:
		if upgrade_levels[upgrade["stat"]] >= upgrade["max_level"]:
			continue
		if upgrade.has("requires") and upgrade["requires"] != "":
			if upgrade_levels.get(upgrade["requires"], 0) < 1:
				continue
		
		var is_new = upgrade_levels[upgrade["stat"]] == 0
		
		if is_new:
			if upgrade["upgrade_type"] == "active" and player and player.active_weapons.size() >= 4:
				continue
			if upgrade["upgrade_type"] == "passive" and player and player.passive_buffs.size() >= 4:
				continue
			new_upgrades.append(upgrade)
		else:
			owned_upgrades.append(upgrade)
	
	var weighted_pool = []
	
	for upgrade in owned_upgrades:
		weighted_pool.append(upgrade)
		weighted_pool.append(upgrade)
	
	for upgrade in new_upgrades:
		weighted_pool.append(upgrade)
	
	weighted_pool.shuffle()
	
	current_choices = []
	var seen = []
	
	for upgrade in weighted_pool:
		if seen.has(upgrade["stat"]):
			continue
		current_choices.append(upgrade)
		seen.append(upgrade["stat"])
		if current_choices.size() >= 3:
			break
	
	if current_choices.size() == 0:
		get_tree().paused = false
		return
	
	show()
	get_tree().paused = true
	
	selected_index = 0
	_update_button(choice1, choice1_label, choice1_icon, 0)
	_update_button(choice2, choice2_label, choice2_icon, 1)
	_update_button(choice3, choice3_label, choice3_icon, 2)
	_update_selection()
	
	choice1.focus_mode = Control.FOCUS_NONE
	choice2.focus_mode = Control.FOCUS_NONE
	choice3.focus_mode = Control.FOCUS_NONE

func _apply_upgrade(index: int):
	if index < current_choices.size():
		var upgrade = current_choices[index]
		upgrade_levels[upgrade["stat"]] += 1
		
		if upgrade["upgrade_type"] == "active":
			active_upgrades_taken += 1
		elif upgrade["upgrade_type"] == "passive":
			passive_upgrades_taken += 1
		
		upgrade_selected.emit(upgrade["stat"])
		close_menu()

func _update_button(button: Button, label: Label, icon: TextureRect, index: int):
	if index < current_choices.size():
		button.show()
		var upgrade = current_choices[index]
		var current_level = upgrade_levels[upgrade["stat"]]
		var max_level = upgrade["max_level"]
		
		icon.texture = upgrade["icon"]
		
		var desc: String
		if upgrade.has("level_descriptions"):
			var next_level = current_level + 1
			desc = upgrade["level_descriptions"].get(next_level, "")
		else:
			desc = upgrade["description"]
		
		label.text = upgrade["name"] + " [" + str(current_level) + "/" + str(max_level) + "]\n" + desc
	else:
		button.hide()

func _on_choice1_pressed():
	_apply_upgrade(0)

func _on_choice2_pressed():
	_apply_upgrade(1)

func _on_choice3_pressed():
	_apply_upgrade(2)

func close_menu():
	hide()
	get_tree().paused = false
