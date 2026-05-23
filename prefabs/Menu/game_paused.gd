extends Control

@onready var continue_button: Button = $NinePatchRect/Continue
@onready var settings_button: Button = $NinePatchRect/Settings
@onready var exit_button: Button = $NinePatchRect/Exit

var original_volume: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_continue_pressed()
		else:
			_pause()

func _pause() -> void:
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
	get_tree().paused = false

func _get_music() -> AudioStreamPlayer:
	return get_tree().root.get_node_or_null("Level/AudioStreamPlayer")

func _on_settings_pressed() -> void:
	pass

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
