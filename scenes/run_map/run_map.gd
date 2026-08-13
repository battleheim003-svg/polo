extends Control

const RUN_ENGINE := preload("res://domain/run/run_engine.gd")

var status_label: Label

func _ready() -> void:
	if GameSession.current_run == null:
		GameSession.continue_run()
	_build()

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "Salar-e Meydan Cup | Stage %d | Coins %d | Credit %d" % [GameSession.current_run.stage, GameSession.current_run.coins, GameSession.current_run.cup_credit]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)
	status_label = Label.new()
	root.add_child(status_label)
	for node in GameSession.current_run.nodes:
		var button := Button.new()
		button.custom_minimum_size = Vector2(1040, 66)
		button.text = "%s | row %d | %s | %s" % [node["id"], int(node["row"]), node["type"], node["preview"]]
		button.disabled = str(node["status"]) != "available"
		button.pressed.connect(_select_node.bind(str(node["id"])))
		root.add_child(button)
	var safe := Button.new()
	safe.text = "Safe Exit"
	safe.custom_minimum_size = Vector2(280, 64)
	safe.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	root.add_child(safe)

func _select_node(node_id: String) -> void:
	var node := _node(node_id)
	match str(node["type"]):
		RUN_ENGINE.NODE_MATCH, RUN_ENGINE.NODE_ELITE, RUN_ENGINE.NODE_BOSS:
			var result := GameSession.start_run_match(node_id)
			if bool(result.get("ok", false)):
				get_tree().change_scene_to_file("res://scenes/preparation/preparation.tscn")
			else:
				status_label.text = str(result.get("reason", "Cannot start node."))
		RUN_ENGINE.NODE_EVENT, RUN_ENGINE.NODE_CAMP, RUN_ENGINE.NODE_MARKET:
			GameSession.current_run.current_node_id = node_id
			get_tree().change_scene_to_file("res://scenes/run_node/run_node.tscn")

func _node(node_id: String) -> Dictionary:
	for node in GameSession.current_run.nodes:
		if str(node["id"]) == node_id:
			return node
	return {}
