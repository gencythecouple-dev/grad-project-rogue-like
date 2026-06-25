extends Node


var unlocked_bgm_tracks: Array[String] = []

var selected_bgm: String = ""
var show_damage_numbers: bool = true
var selected_character: String = "mage"
var selected_weapon: String = "magic_bullet"
var characters = {
	"mage": "res://characters/mage.tscn",
	"rogue": "res://characters/rogue.tscn",
	"warrior": "res://characters/warrior.tscn"
}
var music_gamble_cost: int = 100
var music_volume: float = 100.0
const SAVE_PATH := "user://save.cfg"
var came_from_pause: bool = false
var previous_scene: String = ""

const ALL_BGM_TRACKS: Array[String] = [
	"res://Assets/BGM_SFX/BGM/Demetori - Ego,Schizoid,Beat.mp3",
	"res://Assets/BGM_SFX/UI/Cyber Milk Chan - Condensed Milk.mp3",
	"res://Assets/BGM_SFX/BGM/Everybody Falls.mp3",
	"res://Assets/BGM_SFX/BGM/BGM_1.mp3",
	"res://Assets/BGM_SFX/BGM/BGM_2.mp3"
]

var gold: int = 0

var meta_upgrades: Dictionary = {
	"might": 0,
	"max_hp": 0,
	"armor": 0,
	"move_speed": 0,
	"attack_speed": 0,
	"recovery": 0,
	"magnet": 0,
	"greed": 0,
	"crit": 0,
	"revivals": 0,
	"curse": 0,
}

var unlocked_characters: Dictionary = {
	"mage": false,
	"rogue": true,
	"warrior": false,
}

const UNLOCK_COSTS: Dictionary = {
	"mage": 500,
	"warrior": 750,
}

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "gold", gold)
	for key in meta_upgrades:
		config.set_value("upgrades", key, meta_upgrades[key])
	for key in unlocked_characters:
		config.set_value("unlocks", key, unlocked_characters[key])
	config.set_value("audio", "music_gamble_cost", music_gamble_cost)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "unlocked_bgm", unlocked_bgm_tracks)
	config.set_value("audio", "selected_bgm", selected_bgm)
	config.set_value("gameplay", "damage_numbers", show_damage_numbers)
	config.save(SAVE_PATH)




func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		unlocked_bgm_tracks = ["res://Assets/BGM_SFX/BGM/Demetori - Ego,Schizoid,Beat.mp3"]
		return
	gold = config.get_value("player", "gold", 0)
	for key in meta_upgrades:
		meta_upgrades[key] = config.get_value("upgrades", key, 0)
	for key in unlocked_characters:
		unlocked_characters[key] = config.get_value("unlocks", key, unlocked_characters[key])
	music_gamble_cost = config.get_value("audio", "music_gamble_cost", 100)
	music_volume = config.get_value("audio", "music_volume", 100.0)
	show_damage_numbers = config.get_value("gameplay", "damage_numbers", true)
	selected_bgm = config.get_value("audio", "selected_bgm", "")
	var loaded_tracks = config.get_value("audio", "unlocked_bgm", ["res://Assets/BGM_SFX/BGM/Demetori - Ego,Schizoid,Beat.mp3"])
	for track in loaded_tracks:
		var t := str(track)
		if not unlocked_bgm_tracks.has(t):
			unlocked_bgm_tracks.append(t)



func unlock_random_bgm() -> void:
	var locked: Array[String] = []
	for track in ALL_BGM_TRACKS:
		if not unlocked_bgm_tracks.has(track):
			locked.append(track)
	if locked.is_empty():
		return
	var new_track: String = locked[randi() % locked.size()]
	unlocked_bgm_tracks.append(new_track)
	save()

func add_gold(amount: int) -> void:
	gold += amount
	save()

const UPGRADE_MAX_LEVELS: Dictionary = {
	"might": 5,
	"max_hp": 5,
	"armor": 5,
	"move_speed": 5,
	"attack_speed": 5,
	"recovery": 5,
	"magnet": 5,
	"greed": 5,
	"crit": 5,
	"revivals": 1,
	"curse": 5,
}

func is_maxed(upgrade: String) -> bool:
	return meta_upgrades[upgrade] >= UPGRADE_MAX_LEVELS[upgrade]

func buy_upgrade(upgrade: String, cost: int) -> bool:
	if gold < cost or is_maxed(upgrade):
		return false
	gold -= cost
	meta_upgrades[upgrade] += 1
	save()
	return true

const UPGRADE_INITIAL_COSTS: Dictionary = {
	"might": 200,
	"max_hp": 150,
	"armor": 300,
	"move_speed": 100,
	"attack_speed": 200,
	"recovery": 100,
	"magnet": 75,
	"greed": 100,
	"crit": 150,
	"revivals": 500,
	"curse": 100,
}

func get_upgrade_cost(upgrade: String) -> int:
	var level: int = meta_upgrades[upgrade]
	var initial: int = UPGRADE_INITIAL_COSTS[upgrade]
	return initial * (level + 1)

func reset_music_gamble() -> void:
	music_gamble_cost = 100
	save()

func reset_run_data() -> void:
	selected_character = "mage"
	selected_weapon = "magic_bullet"
