extends Node2D

@onready var play_button: Button = $CenterContainer/VBoxContainer/Play
@onready var option_button: Button = $CenterContainer/VBoxContainer/Option
@onready var quit_button: Button = $CenterContainer/VBoxContainer/Quit
@onready var upgrade_button: Button = $CenterContainer/VBoxContainer/Upgrade

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var is_fullscreen: bool = config.get_value("video", "fullscreen", false)
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			var index: int = config.get_value("video", "resolution_index", 0)
			var RESOLUTIONS := [
				Vector2i(1920, 1080),
				Vector2i(1600, 900),
				Vector2i(1280, 720),
				Vector2i(1024, 576),
			]
			var res: Vector2i = RESOLUTIONS[index]
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(res)
			var screen := DisplayServer.window_get_current_screen()
			var screen_pos := DisplayServer.screen_get_position(screen)
			var screen_size := DisplayServer.screen_get_size(screen)
			var centered := screen_pos + (screen_size - res) / 2
			DisplayServer.window_set_position(centered)
	GameData.load_data()
	AudioManager.play_menu_bgm()
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	option_button.pressed.connect(_on_option_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/Character_selection.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_option_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/settings.tscn")

func _on_upgrade_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Menu/upgrade.tscn")
