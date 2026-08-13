extends Control

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := Label.new()
	title.text = "Choose Reward"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	root.add_child(title)
	for reward in GameSession.current_run.pending_reward_pool:
		var button := Button.new()
		button.custom_minimum_size = Vector2(720, 80)
		button.text = "%s | %s +%d" % [reward["name"], reward["type"], int(reward["amount"])]
		button.pressed.connect(func(id := str(reward["id"])) -> void:
			GameSession.apply_run_reward(id)
			if GameSession.current_run.status in ["won", "lost"]:
				get_tree().change_scene_to_file("res://scenes/run_result/run_result.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/run_map/run_map.tscn")
		)
		root.add_child(button)
