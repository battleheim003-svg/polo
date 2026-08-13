extends Control

func _ready() -> void:
	var s := GameSession.current_state
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	var title := Label.new()
	title.text = "نتیجه مسابقه"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	root.add_child(title)
	var summary := Label.new()
	summary.text = "بازیکن %d - %d حریف\nگل‌ها: %d | پاس: %d | هوک: %d | راید-آف: %d | خطا: %d\nبهترین سوار: %s\nSeed: %d" % [s.scores[0], s.scores[1], s.stats["goals"], s.stats["passes"], s.stats["hooks"], s.stats["ride_offs"], s.stats["fouls"], _best_rider_name(), s.seed]
	root.add_child(summary)
	if GameSession.returning_from_run_match:
		var run_result := GameSession.finish_run_match()
		var continue_run := Button.new()
		continue_run.text = "Continue Run"
		continue_run.custom_minimum_size = Vector2(480, 76)
		continue_run.pressed.connect(func() -> void:
			if GameSession.current_run.pending_reward_pool.size() > 0:
				get_tree().change_scene_to_file("res://scenes/run_reward/run_reward.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/run_map/run_map.tscn")
		)
		root.add_child(continue_run)
		var result_label := Label.new()
		result_label.text = "Run status: %s" % str(run_result.get("status", "running"))
		root.add_child(result_label)
		return
	var replay := Button.new()
	replay.text = "مسابقه مجدد با همین Seed"
	replay.custom_minimum_size = Vector2(480, 76)
	replay.pressed.connect(func() -> void:
		GameSession.replay_same_seed()
		get_tree().change_scene_to_file("res://scenes/match/match.tscn")
	)
	root.add_child(replay)
	var new_seed := Button.new()
	new_seed.text = "Seed جدید"
	new_seed.custom_minimum_size = Vector2(480, 76)
	new_seed.pressed.connect(func() -> void:
		GameSession.new_seed()
		get_tree().change_scene_to_file("res://scenes/match/match.tscn")
	)
	root.add_child(new_seed)
	var back := Button.new()
	back.text = "بازگشت"
	back.custom_minimum_size = Vector2(480, 76)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/menu/menu.tscn"))
	root.add_child(back)

func _best_rider_name() -> String:
	var best := ""
	var stamina := -1
	for rider in GameSession.current_state.riders:
		if int(rider["stamina"]) > stamina:
			stamina = int(rider["stamina"])
			best = str(rider["id"])
	return GameSession.repository.riders[best].name_fa if GameSession.repository.riders.has(best) else best
