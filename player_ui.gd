extends CanvasLayer

@onready var exp_bar = $"MarginContainer/VBoxContainer/ExpBar"
@onready var level_label = $"MarginContainer/VBoxContainer/LevelLabel"

func _ready():
	add_to_group("PlayerUI")
	print("PlayerUI _ready - exp_bar: ", exp_bar, " level_label: ", level_label)
	if exp_bar:
		exp_bar.show_percentage = false

func update_exp(current: int, needed: int):
	if exp_bar == null:
		print("ERROR: exp_bar is null!")
		return
	exp_bar.max_value = needed
	exp_bar.value = current

func update_level(level: int):
	if level_label == null:
		print("ERROR: level_label is null!")
		return
	level_label.text = "Level " + str(level)
