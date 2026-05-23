extends Node

var selected_character: String = "mage"
var selected_weapon: String = "magic_bullet"
var characters = {
	"mage": "res://characters/mage.tscn",
	"rogue": "res://characters/rogue.tscn",
	"warrior": "res://characters/warrior.tscn"
}

const SAVE_PATH := "user://save.cfg"

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

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "gold", gold)
	for key in meta_upgrades:
		config.set_value("upgrades", key, meta_upgrades[key])
	config.save(SAVE_PATH)

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	gold = config.get_value("player", "gold", 0)
	for key in meta_upgrades:
		meta_upgrades[key] = config.get_value("upgrades", key, 0)

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

func reset_run_data() -> void:
	selected_character = "mage"
	selected_weapon = "magic_bullet"
