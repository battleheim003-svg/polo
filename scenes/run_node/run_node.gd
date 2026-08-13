extends Control

func _ready() -> void:
	var node := _node(GameSession.current_run.current_node_id)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var title := Label.new()
	title.text = "%s: %s" % [node["type"], node["id"]]
	title.add_theme_font_size_override("font_size", 42)
	root.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = str(node["preview"])
	root.add_child(body)
	_add_option(root, "Balanced Choice", "default")
	_add_option(root, "Spend Cup Credit", "credit")

func _add_option(root: VBoxContainer, label: String, option: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(520, 76)
	button.pressed.connect(func() -> void:
		GameSession.apply_run_node(GameSession.current_run.current_node_id, option)
		if GameSession.current_run.status in ["won", "lost"]:
			get_tree().change_scene_to_file("res://scenes/run_result/run_result.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/run_map/run_map.tscn")
	)
	root.add_child(button)

func _node(node_id: String) -> Dictionary:
	for node in GameSession.current_run.nodes:
		if str(node["id"]) == node_id:
			return node
	return {}
