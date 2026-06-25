extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"

@onready var master_slider: RunawaySlider = $Panel/CenterContainer/GridContainer/HBoxContainer2/RunawaySlider
@onready var master_label: Label = $Panel/CenterContainer/GridContainer/HBoxContainer2/MasterValue
@onready var sfx_slider: HSlider = $Panel/CenterContainer/GridContainer/HBoxContainer3/SFXSlider
@onready var sfx_label: Label = $Panel/CenterContainer/GridContainer/HBoxContainer3/SFXValue
@onready var music_label: Label = $Panel/CenterContainer/GridContainer/HBoxContainer/MusicValue
@onready var resolution_option: OptionButton = $Panel/CenterContainer/GridContainer/ResolutionOption
@onready var damage_toggle: CheckButton = $Panel/CenterContainer/GridContainer/DamageToggle
@onready var gold_label: Label = $Panel/CenterContainer/GridContainer/HBoxContainer/GoldLabel
@onready var gamble_button: Button = $Panel/CenterContainer/GridContainer/HBoxContainer/GambleButton
@onready var music_slider_display: HSlider = $Panel/CenterContainer/GridContainer/HBoxContainer/MusicSlider
@onready var fullscreen_toggle: CheckButton = $Panel/CenterContainer/GridContainer/FullScreenToggle



var is_overlay: bool = false
var pause_menu_ref = null

const RESOLUTIONS := [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1024, 576),
]

func _ready() -> void:
	if not GameData.came_from_pause:
		AudioManager.play_menu_bgm()
	_populate_resolutions()
	load_settings()
	master_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	resolution_option.item_selected.connect(_on_resolution_changed)
	gamble_button.pressed.connect(_on_gamble_pressed)
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_update_gamble_ui()

func _populate_resolutions() -> void:
	resolution_option.clear()
	for res in RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		master_slider.value = 100
		sfx_slider.value = 100
		resolution_option.selected = 0
		damage_toggle.button_pressed = true
		_apply_volumes()
		return
	var is_fullscreen: bool = config.get_value("video", "fullscreen", false)
	fullscreen_toggle.button_pressed = is_fullscreen
	_apply_fullscreen(is_fullscreen)
	master_slider.set_value(config.get_value("audio", "master", 100))
	music_slider_display.value = GameData.music_volume
	sfx_slider.value = config.get_value("audio", "sfx", 100)
	resolution_option.selected = config.get_value("video", "resolution_index", 0)
	if damage_toggle.toggled.is_connected(_on_damage_toggled):
		damage_toggle.toggled.disconnect(_on_damage_toggled)
	damage_toggle.button_pressed = GameData.show_damage_numbers
	damage_toggle.toggled.connect(_on_damage_toggled)
	_update_labels()
	_update_gamble_ui()
	_apply_volumes()
	_apply_resolution(resolution_option.selected, true)


func _update_gamble_ui() -> void:
	music_label.text = "%d%%" % int(GameData.music_volume)
	music_slider_display.value = GameData.music_volume
	gold_label.text = "Cost: %dg" % GameData.music_gamble_cost
	gamble_button.disabled = GameData.gold < GameData.music_gamble_cost

func _on_gamble_pressed() -> void:
	if GameData.gold < GameData.music_gamble_cost:
		return
	GameData.gold -= GameData.music_gamble_cost
	GameData.music_gamble_cost *= 2
	GameData.music_volume = randf_range(0.0, 100.0)
	GameData.save()
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(GameData.music_volume / 100.0)
	)
	_update_gamble_ui()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("video", "resolution_index", resolution_option.selected)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	config.set_value("gameplay", "damage_numbers", damage_toggle.button_pressed)
	config.save(SETTINGS_PATH)

func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_slider.value / 100.0)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_slider.value / 100.0)
	)

func _update_labels() -> void:
	master_label.text = "%d%%" % int(clamp(master_slider.value, 0, 100))
	sfx_label.text = "%d%%" % sfx_slider.value

func _apply_resolution(index: int, from_load: bool = false) -> void:
	var res: Vector2i = RESOLUTIONS[index]
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return
	if from_load and current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(res)
	var screen := DisplayServer.window_get_current_screen()
	var screen_pos := DisplayServer.screen_get_position(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var centered := screen_pos + (screen_size - res) / 2
	DisplayServer.window_set_position(centered)

func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)
	save_settings()

func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		var index := resolution_option.selected
		var res: Vector2i = RESOLUTIONS[index]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(res)
		var screen_size := DisplayServer.screen_get_size()
		var centered := (screen_size - res) / 2
		DisplayServer.window_set_position(centered)

func _on_master_changed(_value: float) -> void:
	master_label.text = "%d%%" % int(clamp(master_slider.value, 0, 100))
	_apply_volumes()
	save_settings()

func _on_sfx_changed(_value: float) -> void:
	sfx_label.text = "%d%%" % sfx_slider.value
	_apply_volumes()
	save_settings()

func _on_resolution_changed(index: int) -> void:
	_apply_resolution(index)
	save_settings()

func _on_damage_toggled(pressed: bool) -> void:
	GameData.show_damage_numbers = pressed
	GameData.save()
	save_settings()

func _on_return_pressed() -> void:
	if is_overlay:
		GameData.came_from_pause = false
		pause_menu_ref.set_process_input(true)
		pause_menu_ref.show()
		queue_free()
	else:
		get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
