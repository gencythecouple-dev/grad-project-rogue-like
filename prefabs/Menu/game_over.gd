extends CanvasLayer

@onready var time_survived: Label = $ColorRect/NinePatchRect/VBoxContainer/TimeSurvived
@onready var total_kills: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalKills
@onready var total_damage: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalDamage
@onready var total_exp: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalExp
@onready var gold_earned: Label = $ColorRect/NinePatchRect/VBoxContainer/GoldEarned
@onready var retry: Button = $ColorRect/Retry
@onready var menu: Button = $ColorRect/Menu
@onready var screen_title: Label = $ColorRect/ScreenTitle
@onready var bgm_unlocked_label: Label = $ColorRect/NinePatchRect/VBoxContainer/BGM_Unlocked


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	retry.pressed.connect(_on_retry_pressed)
	menu.pressed.connect(_on_menu_pressed)

func setup(time: float, kills: int, damage: float, exp: int, run_gold: int, is_win: bool = false) -> void:
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	var kill_gold := int(kills / 4)
	var total_gold := run_gold + kill_gold
	bgm_unlocked_label.hide()
	if is_win:
		total_gold += 500
		GameData.reset_music_gamble()
		var tracks_before := GameData.unlocked_bgm_tracks.size()
		GameData.unlock_random_bgm()
		var tracks_after := GameData.unlocked_bgm_tracks.size()
		if tracks_after > tracks_before:
			var new_track = GameData.unlocked_bgm_tracks.back()
			var track_name = new_track.get_file().get_basename()
			bgm_unlocked_label.text = "🎵 New BGM Unlocked: " + track_name
			bgm_unlocked_label.show()
	GameData.add_gold(total_gold)
	AudioManager.play_game_over()
	time_survived.text = "Time Survived: %02d:%02d" % [minutes, seconds]
	total_kills.text = "Total Kills: " + str(kills)
	total_damage.text = "Total Damage Dealt: " + str(int(damage))
	total_exp.text = "Total EXP Collected: " + str(exp)
	gold_earned.text = "Gold Earned: " + str(total_gold) + ("  (+500 BONUS!)" if is_win else "")
	screen_title.text = "ABSOLVED" if is_win else "FORSAKEN"
	show()
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://level.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
