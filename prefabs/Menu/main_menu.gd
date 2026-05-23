extends Node2D

@onready var play_button: Button = $CenterContainer/VBoxContainer/Play
@onready var option_button: Button = $CenterContainer/VBoxContainer/Option
@onready var quit_button: Button = $CenterContainer/VBoxContainer/Quit
@onready var upgrade_button: Button = $CenterContainer/VBoxContainer/Upgrade

func _ready() -> void:
	GameData.load_data()
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	option_button.pressed.connect(_on_option_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/Character_selection.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_option_pressed() -> void:
	pass

func _on_upgrade_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/upgrade.tscn")
