extends AudioStreamPlayer

var level_ref: Node
var current_track: String = ""

func _ready() -> void:
	level_ref = get_tree().root.get_node("Level")
	_start_track()

func _start_track() -> void:
	if not GameData.selected_bgm.is_empty() and GameData.unlocked_bgm_tracks.has(GameData.selected_bgm):
		current_track = GameData.selected_bgm
	else:
		current_track = "res://Assets/BGM_SFX/BGM/Demetori - Ego,Schizoid,Beat.mp3"
	var audio: AudioStream = load(current_track)
	if audio is AudioStreamOggVorbis:
		audio.loop = true
	if audio is AudioStreamMP3:
		audio.loop = true
	stream = audio
	play()

func change_track(new_track: String) -> void:
	current_track = new_track
	var audio: AudioStream = load(new_track)
	if audio is AudioStreamOggVorbis:
		audio.loop = true
	if audio is AudioStreamMP3:
		audio.loop = true
	stream = audio
	play()

func duck() -> void:
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -20.0, 0.5)

func unduck() -> void:
	var tween = create_tween()
	tween.tween_property(self, "volume_db", 0.0, 0.5)
