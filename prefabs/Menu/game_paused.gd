extends Control

@onready var continue_button: Button = $NinePatchRect/Continue
@onready var settings_button: Button = $NinePatchRect/Settings
@onready var exit_button: Button = $NinePatchRect/Exit


var came_from_pause: bool = false
var original_volume: float = 0.0
var settings_instance = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var is_level_up_open = false
		for node in get_tree().get_nodes_in_group("PlayerUI"):
			if node.get_script() and node.get_script().resource_path.contains("LevelUpMenu"):
				is_level_up_open = node.is_open
				break
		print("is_level_up_open: ", is_level_up_open)
		if is_level_up_open:
			return
		if visible:
			_on_continue_pressed()
		else:
			_pause()

func _pause() -> void:
	if get_tree().paused:
		return
	var music := _get_music()
	if music:
		original_volume = music.volume_db
		music.volume_db = -20.0
	show()
	get_tree().paused = true

func _on_continue_pressed() -> void:
	var music := _get_music()
	if music:
		music.volume_db = original_volume
	hide()
	for node in get_tree().get_nodes_in_group("PlayerUI"):
		if node.get_script() and node.get_script().resource_path.contains("LevelUpMenu"):
			if node.is_open:
				return
			break
	get_tree().paused = false

func _get_music() -> AudioStreamPlayer:
	return get_tree().root.get_node_or_null("Level/AudioStreamPlayer")

func _on_settings_pressed() -> void:
	GameData.came_from_pause = true
	var settings_scene = preload("res://prefabs/settings.tscn")
	settings_instance = settings_scene.instantiate()
	settings_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(settings_instance)
	settings_instance.is_overlay = true
	settings_instance.pause_menu_ref = self
	set_process_input(false)
	hide()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
