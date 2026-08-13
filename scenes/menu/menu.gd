extends Control

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	var title := Label.new()
	title.text = "چوگان: سالار میدان"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	root.add_child(title)
	var start := Button.new()
	start.text = "آماده‌سازی تیم"
	start.custom_minimum_size = Vector2(420, 80)
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/preparation/preparation.tscn"))
	root.add_child(start)
	var quick := Button.new()
	quick.text = "شروع سریع"
	quick.custom_minimum_size = Vector2(420, 80)
	quick.pressed.connect(func() -> void:
		GameSession.start_match()
		get_tree().change_scene_to_file("res://scenes/match/match.tscn")
	)
	root.add_child(quick)
