extends Node2D
class_name Level

@onready var arrow_holder := $ArrowHolder
@onready var enemy_holder := $EnemyHolder
var enemy_list = []

func _ready() -> void:
	GetEnemies()
		
func GetEnemies():
	enemy_list = []
	for child in enemy_holder.get_children():
		enemy_list.append(child)
