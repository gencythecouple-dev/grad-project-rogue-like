extends PanelContainer

@onready var track_name: Label = $VBoxContainer/HBoxContainer/TrackName
@onready var prev_button: TextureButton = $VBoxContainer/HBoxContainer/PrevButton
@onready var next_button: TextureButton = $VBoxContainer/HBoxContainer/NextButton

const DEFAULT_TRACK := "res://Assets/BGM_SFX/BGM/Demetori - Ego,Schizoid,Beat.mp3"

func _ready() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	_update_display()

func _update_display() -> void:
	if GameData.unlocked_bgm_tracks.is_empty():
		track_name.text = "No tracks unlocked yet"
		return
	if GameData.selected_bgm.is_empty():
		GameData.selected_bgm = GameData.unlocked_bgm_tracks[0]
	track_name.text = GameData.selected_bgm.get_file().get_basename()

func _on_prev_pressed() -> void:
	var tracks := GameData.unlocked_bgm_tracks
	if tracks.size() <= 1:
		return
	var current_index := tracks.find(GameData.selected_bgm)
	current_index = (current_index - 1 + tracks.size()) % tracks.size()
	GameData.selected_bgm = tracks[current_index]
	GameData.save()
	_update_display()
	_change_ingame_track()

func _on_next_pressed() -> void:
	var tracks := GameData.unlocked_bgm_tracks
	if tracks.size() <= 1:
		return
	var current_index := tracks.find(GameData.selected_bgm)
	current_index = (current_index + 1) % tracks.size()
	GameData.selected_bgm = tracks[current_index]
	GameData.save()
	_update_display()
	_change_ingame_track()

func _change_ingame_track() -> void:
	var bgm_player = get_tree().root.get_node_or_null("Level/AudioStreamPlayer")
	if bgm_player and bgm_player.has_method("change_track"):
		var track := GameData.selected_bgm if not GameData.selected_bgm.is_empty() else DEFAULT_TRACK
		bgm_player.change_track(track)
