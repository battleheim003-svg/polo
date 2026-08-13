extends Control

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var title := Label.new()
	title.text = "Run Complete: %s" % GameSession.current_run.status
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	root.add_child(title)
	var summary := Label.new()
	summary.text = "Matches %d | Coins %d | Credit %d | Path %s" % [GameSession.current_run.match_history.size(), GameSession.current_run.coins, GameSession.current_run.cup_credit, ",".join(GameSession.current_run.path)]
	root.add_child(summary)
	var next := Button.new()
	next.text = "Start New Run"
	next.custom_minimum_size = Vector2(420, 76)
	next.pressed.connect(func() -> void:
		GameSession.new_seed()
		GameSession.start_new_run(GameSession.current_seed)
		get_tree().change_scene_to_file("res://scenes/run_map/run_map.tscn")
	)
	root.add_child(next)
	var menu := Button.new()
	menu.text = "Menu"
	menu.custom_minimum_size = Vector2(420, 76)
	menu.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	root.add_child(menu)
