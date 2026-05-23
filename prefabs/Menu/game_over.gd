extends CanvasLayer

@onready var time_survived: Label = $ColorRect/NinePatchRect/VBoxContainer/TimeSurvived
@onready var total_kills: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalKills
@onready var total_damage: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalDamage
@onready var total_exp: Label = $ColorRect/NinePatchRect/VBoxContainer/TotalExp
@onready var gold_earned: Label = $ColorRect/NinePatchRect/VBoxContainer/GoldEarned
@onready var retry: Button = $ColorRect/Retry
@onready var menu: Button = $ColorRect/Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	retry.pressed.connect(_on_retry_pressed)
	menu.pressed.connect(_on_menu_pressed)

func setup(time: float, kills: int, damage: float, exp: int, run_gold: int) -> void:
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	var kill_gold := int(kills / 4)
	var total_gold := run_gold + kill_gold
	GameData.add_gold(total_gold)
	time_survived.text = "Time Survived: %02d:%02d" % [minutes, seconds]
	total_kills.text = "Total Kills: " + str(kills)
	total_damage.text = "Total Damage Dealt: " + str(int(damage))
	total_exp.text = "Total EXP Collected: " + str(exp)
	gold_earned.text = "Gold Earned: " + str(total_gold)
	show()
	get_tree().paused = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://level.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://prefabs/Menu/main_menu.tscn")
