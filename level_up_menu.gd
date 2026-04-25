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

var all_upgrades := [
	#{
		##"name": "Increase Attack", 
		#"description": "+1 Attack Damage", 
		#"stat": "attack", 
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "active"  
	#},
	#{
		#"name": "Increase Max HP", 
		#"description": "+10 Max Health", 
		#"stat": "max_hp", 
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "passive"  
	#},
	#{
		#"name": "Attack Speed", 
		#"description": "+15% Faster Attacks", 
		#"stat": "attack_speed", 
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "passive"  
	#},
	#{
		#"name": "Movement Speed", 
		#"description": "+15% Move Speed", 
		#"stat": "move_speed", 
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "passive" 
	#},
	#{
		#"name": "Max HP Up", 
		#"description": "+20 Max Health + Full Heal", 
		#"stat": "max_hp_big", 
		#"max_level": 3,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "passive" 
	#},
	#{
		#"name": "Damage Boost", 
		#"description": "+2 Attack Damage", 
		#"stat": "attack_big", 
		#"max_level": 3,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "active" 
	#},
	#{
		#"name": "More Arrows!", 
		#"description": "+1 Arrow Projectile", 
		#"stat": "more_projectile", 
		#"max_level": 3,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "active"  
	#},
	#{
		#"name": "Ice Hammer",
		#"stat": "ice_hammer",
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "active",
		#"requires": "",
		#"level_descriptions": {
			#1: "Unlock the Ice Hammer!",
			#2: "+2 Damage",
			#3: "Bigger Spikes",
			#4: "Faster Cooldown",
			#5: "ALL: +Damage, Bigger, Faster + Ice Shockwave!"
		#},
		#},
		#{
		#"name": "Iron Skin",
		#"description": "Reduce incoming damage",
		#"stat": "armor",
		#"max_level": 5,
		#"icon": preload("res://Assets/UIBundleFree/UIBundleFree/move_speed.png"),
		#"upgrade_type": "passive",
		#"requires": ""
	#},
	{
		"name": "Magic Bullet",
		"description": "Fire a magical bullet at the closest enemy",
		"stat": "magic_bullet",
		"max_level": 5,
		"icon": preload("res://Assets/magic_bullet.png"),
		"upgrade_type": "active",
		"requires": ""
	}
]

var upgrade_levels := {}
var current_choices := []

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for upgrade in all_upgrades:
		upgrade_levels[upgrade["stat"]] = 0
	
	choice1.pressed.connect(_on_choice1_pressed)
	choice2.pressed.connect(_on_choice2_pressed)
	choice3.pressed.connect(_on_choice3_pressed)

func show_upgrades():
	var available = []
	var owned_upgrades = []
	var new_upgrades = []
	
	for upgrade in all_upgrades:
		if upgrade_levels[upgrade["stat"]] >= upgrade["max_level"]:
			continue
		if upgrade.has("requires") and upgrade["requires"] != "":
			if upgrade_levels.get(upgrade["requires"], 0) < 1:
				continue
		if upgrade_levels[upgrade["stat"]] > 0:
			owned_upgrades.append(upgrade)
		else:
			new_upgrades.append(upgrade)
	
	owned_upgrades.shuffle()
	new_upgrades.shuffle()
	available = owned_upgrades + new_upgrades
	
	current_choices = []
	var num_choices = min(3, available.size())
	for i in range(num_choices):
		current_choices.append(available[i])
	
	if available.size() == 0:
		get_tree().paused = false
		return

	show()
	get_tree().paused = true
	available.shuffle()
	current_choices = []
	for i in range(num_choices):
		current_choices.append(available[i])

	_update_button(choice1, choice1_label, choice1_icon, 0)
	_update_button(choice2, choice2_label, choice2_icon, 1)
	_update_button(choice3, choice3_label, choice3_icon, 2)

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
