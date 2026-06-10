extends Node2D

@onready var select_mage: Button = $CanvasLayer/HBoxContainer/Card1/VBoxContainer/Select1
@onready var select_rogue: Button = $CanvasLayer/HBoxContainer/Card2/VBoxContainer/Select2
@onready var select_warrior: Button = $CanvasLayer/HBoxContainer/Card3/VBoxContainer/Select3
@onready var back_button: Button = $CanvasLayer/Back

@onready var panel1: PanelContainer = $CanvasLayer/PanelContainer
@onready var weapon_info1: Label = $CanvasLayer/PanelContainer/Control/WeaponInfo
@onready var weapon_icon1: TextureRect = $CanvasLayer/PanelContainer/WeaponIcon
@onready var lore: Label = $CanvasLayer/HBoxContainer/Card1/Sprite1/Lore
@onready var lock_overlay: ColorRect = $CanvasLayer/HBoxContainer/Card1/LockOverlay



@onready var panel2: PanelContainer = $CanvasLayer/PanelContainer2
@onready var weapon_info2: Label = $CanvasLayer/PanelContainer2/Control/WeaponInfo2
@onready var weapon_icon2: TextureRect = $CanvasLayer/PanelContainer2/WeaponIcon2

@onready var panel3: PanelContainer = $CanvasLayer/PanelContainer3
@onready var weapon_info3: Label = $CanvasLayer/PanelContainer3/Control/WeaponInfo3
@onready var weapon_icon3: TextureRect = $CanvasLayer/PanelContainer3/WeaponIcon3
@onready var lore3: Label = $CanvasLayer/HBoxContainer/Card3/Sprite3/Lore3
@onready var lock_overlay3: ColorRect = $CanvasLayer/HBoxContainer/Card3/LockOverlay3



func _ready() -> void:
	panel1.hide()
	panel2.hide()
	panel3.hide()
	weapon_icon1.texture = preload("res://Assets/magic_bullet.png")
	weapon_info1.text = "Mystic Orb : Automatically seeks the nearest enemy. Upgrade it to fire more orbs at once and pierce through crowds."
	weapon_icon2.texture = preload("res://Assets/knife_icon.png")
	weapon_info2.text = "Phantom Edge : Hurls knives in your movement direction. The faster you move, the more dangerous you become."
	weapon_icon3.texture = preload("res://Assets/Sword/sword.png")
	weapon_info3.text = "Crimson Edge : A wide slash that punishes anything in melee range. Reach its full potential and it becomes a spinning death aura."
	select_mage.pressed.connect(_on_select_mage_pressed)
	select_rogue.pressed.connect(_on_select_rogue_pressed)
	select_warrior.pressed.connect(_on_select_warrior_pressed)
	back_button.pressed.connect(_on_back_pressed)
	select_mage.mouse_entered.connect(func(): if GameData.unlocked_characters["mage"]: panel1.show())
	select_mage.mouse_exited.connect(func(): panel1.hide())
	select_rogue.mouse_entered.connect(func(): if GameData.unlocked_characters["rogue"]: panel2.show())
	select_rogue.mouse_exited.connect(func(): panel2.hide())
	select_warrior.mouse_entered.connect(func(): if GameData.unlocked_characters["warrior"]: panel3.show())
	select_warrior.mouse_exited.connect(func(): panel3.hide())
	_update_card_states()

func _update_card_states() -> void:
	_apply_card_state("mage", lock_overlay, lore, select_mage)
	_apply_card_state("warrior", lock_overlay3, lore3, select_warrior)

func _apply_card_state(character: String, overlay: ColorRect, lore: Label, button: Button) -> void:
	var unlocked = GameData.unlocked_characters[character]
	overlay.visible = not unlocked
	lore.visible = unlocked
	if unlocked:
		button.text = "SELECT"
		button.disabled = false
	else:
		button.text = "UNLOCK (%dg)" % GameData.UNLOCK_COSTS[character]
		button.disabled = GameData.gold < GameData.UNLOCK_COSTS[character]

func _on_select_mage_pressed() -> void:
	if not GameData.unlocked_characters["mage"]:
		if GameData.gold < GameData.UNLOCK_COSTS["mage"]:
			return
		GameData.gold -= GameData.UNLOCK_COSTS["mage"]
		GameData.unlocked_characters["mage"] = true
		GameData.save()
		_update_card_states()
		return
	GameData.selected_character = "mage"
	GameData.selected_weapon = "magic_bullet"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_select_rogue_pressed() -> void:
	GameData.selected_character = "rogue"
	GameData.selected_weapon = "knife"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_select_warrior_pressed() -> void:
	if not GameData.unlocked_characters["warrior"]:
		if GameData.gold < GameData.UNLOCK_COSTS["warrior"]:
			return
		GameData.gold -= GameData.UNLOCK_COSTS["warrior"]
		GameData.unlocked_characters["warrior"] = true
		GameData.save()
		_update_card_states()
		return
	GameData.selected_character = "warrior"
	GameData.selected_weapon = "sword"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
