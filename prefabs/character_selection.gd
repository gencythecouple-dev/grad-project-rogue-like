extends Node2D

@onready var select_mage: Button = $CanvasLayer/HBoxContainer/Card1/VBoxContainer/Select1
@onready var select_rogue: Button = $CanvasLayer/HBoxContainer/Card2/VBoxContainer/Select2
@onready var select_warrior: Button = $CanvasLayer/HBoxContainer/Card3/VBoxContainer/Select3
@onready var back_button: Button = $CanvasLayer/Tittle/Back

func _ready() -> void:
	select_mage.pressed.connect(_on_select_mage_pressed)
	select_rogue.pressed.connect(_on_select_rogue_pressed)
	select_warrior.pressed.connect(_on_select_warrior_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_select_mage_pressed() -> void:
	GameData.selected_character = "mage"
	GameData.selected_weapon = "arrow"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_select_rogue_pressed() -> void:
	GameData.selected_character = "rogue"
	GameData.selected_weapon = "arrow"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_select_warrior_pressed() -> void:
	GameData.selected_character = "warrior"
	GameData.selected_weapon = "arrow"
	get_tree().change_scene_to_file("res://level.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Main Menu.tscn")
