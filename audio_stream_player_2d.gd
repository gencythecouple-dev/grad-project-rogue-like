extends AudioStreamPlayer

const TRACKS: Array = [
	"res://Assets/BGM and SFX/Cloak Of Darkness 1.ogg",
	"res://Assets/BGM and SFX/Cloak of Darkness 2 (1).ogg",
	"res://Assets/BGM and SFX/Cloak Of Darkness 2.ogg",
	"res://Assets/BGM and SFX/Cloak of Darkness 3 (1).ogg",
	"res://Assets/BGM and SFX/Cloak of Darkness 3.ogg",
]

const TRACK_TIMES: Array = [0, 60, 120, 360, 540]

var current_track: int = -1
var level_ref: Node

func _ready() -> void:
	level_ref = get_tree().root.get_node("Level")
	_check_track()

func _process(_delta: float) -> void:
	_check_track()

func _check_track() -> void:
	if level_ref == null:
		return
	var game_time: float = level_ref.game_time
	var target_track: int = 0
	for i in range(TRACK_TIMES.size()):
		if game_time >= TRACK_TIMES[i]:
			target_track = i
	if target_track != current_track:
		current_track = target_track
		var audio: AudioStream = load(TRACKS[current_track])
		if audio is AudioStreamOggVorbis:
			audio.loop = true
		stream = audio
		play()
		
func duck() -> void:
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -20.0, 0.5)

func unduck() -> void:
	var tween = create_tween()
	tween.tween_property(self, "volume_db", 0.0, 0.5)
