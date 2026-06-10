extends Node

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_connect_all_existing_buttons(get_tree().root)

func _connect_all_existing_buttons(node: Node) -> void:
	for child in node.get_children():
		_on_node_added(child)
		_connect_all_existing_buttons(child)

func _on_node_added(node: Node) -> void:
	if node is Button or node is OptionButton or node is CheckButton:
		if not node.mouse_entered.is_connected(func(): AudioManager.play_ui_hover()):
			node.mouse_entered.connect(func(): 
				if not node.disabled:
					AudioManager.play_ui_hover()
			)
			node.pressed.connect(func(): AudioManager.play_ui_click())
