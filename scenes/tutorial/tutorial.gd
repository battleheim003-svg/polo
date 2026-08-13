extends Control

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)
	var title := Label.new()
	title.text = "Chogan Cup Briefing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	root.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = "Win three cup matches. Choose a path, prepare your four riders, use coach commands, take rewards, and spend coins at camp or market before the boss."
	root.add_child(body)
	var skip := Button.new()
	skip.text = "Start Run"
	skip.custom_minimum_size = Vector2(360, 76)
	skip.pressed.connect(func() -> void:
		SaveService.data["meta"]["tutorial_seen"] = true
		SaveService.save()
		GameSession.start_new_run(GameSession.current_seed)
		get_tree().change_scene_to_file("res://scenes/run_map/run_map.tscn")
	)
	root.add_child(skip)
	var repeat := Button.new()
	repeat.text = "Replay Later"
	repeat.custom_minimum_size = Vector2(360, 64)
	repeat.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	root.add_child(repeat)
