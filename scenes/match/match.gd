extends Control

var score_label: Label
var state_label: Label
var riders_label: Label
var breakdown_label: Label
var event_log: RichTextLabel
var break_panel: HBoxContainer
var ball: ColorRect
var zone_nodes: Array[ColorRect] = []
var display_speed: float = 1.0
var event_queue: Array[MatchEvent] = []

func _ready() -> void:
	if GameSession.current_state == null:
		GameSession.start_match()
	_build_ui()
	_refresh()

func _process(_delta: float) -> void:
	if event_queue.is_empty():
		if GameSession.current_state.status == "ended":
			get_tree().change_scene_to_file("res://scenes/results/results.tscn")
			return
		if GameSession.current_state.substitution_pending or GameSession.current_state.status == "between_chukkers":
			break_panel.visible = true
			_refresh()
			return
		event_queue.append_array(GameSession.tick(GameSession.selected_command))
	else:
		var e: MatchEvent = event_queue.pop_front()
		_apply_event_visual(e)
		event_log.append_text("\n[%s] %s" % [e.type, e.message])
	_refresh()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 40)
	root.add_child(score_label)
	var field := HBoxContainer.new()
	field.custom_minimum_size = Vector2(1800, 300)
	root.add_child(field)
	for i in range(5):
		var zone := ColorRect.new()
		zone.color = Color(0.16 + i * 0.05, 0.22 + i * 0.03, 0.18 + i * 0.02)
		zone.custom_minimum_size = Vector2(340, 280)
		field.add_child(zone)
		zone_nodes.append(zone)
	ball = ColorRect.new()
	ball.color = Color(0.92, 0.78, 0.22)
	ball.custom_minimum_size = Vector2(36, 36)
	add_child(ball)
	var buttons := HBoxContainer.new()
	root.add_child(buttons)
	for tactic in GameSession.repository.tactics.values():
		var button := Button.new()
		button.text = str(tactic["name_en"])
		button.custom_minimum_size = Vector2(210, 64)
		button.pressed.connect(func(id := str(tactic["id"])) -> void: GameSession.selected_command = id)
		buttons.add_child(button)
	var speed := Button.new()
	speed.text = "x2"
	speed.custom_minimum_size = Vector2(100, 64)
	speed.pressed.connect(func() -> void: display_speed = 2.0 if display_speed == 1.0 else 1.0)
	buttons.add_child(speed)
	break_panel = HBoxContainer.new()
	break_panel.visible = false
	break_panel.add_theme_constant_override("separation", 12)
	root.add_child(break_panel)
	var rest := Button.new()
	rest.text = "Keep Lineup"
	rest.custom_minimum_size = Vector2(260, 64)
	rest.pressed.connect(func() -> void:
		event_queue.append_array(GameSession.apply_break_decision("rest"))
		break_panel.visible = false
	)
	break_panel.add_child(rest)
	var swap := Button.new()
	swap.text = "Break Substitution"
	swap.custom_minimum_size = Vector2(300, 64)
	swap.pressed.connect(func() -> void:
		event_queue.append_array(GameSession.apply_break_decision("swap"))
		break_panel.visible = false
	)
	break_panel.add_child(swap)
	state_label = Label.new()
	root.add_child(state_label)
	riders_label = Label.new()
	riders_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(riders_label)
	breakdown_label = Label.new()
	breakdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(breakdown_label)
	event_log = RichTextLabel.new()
	event_log.custom_minimum_size = Vector2(1800, 270)
	root.add_child(event_log)

func _refresh() -> void:
	var s := GameSession.current_state
	score_label.text = "Player %d - %d Rival" % [s.scores[0], s.scores[1]]
	state_label.text = "Chukker %d | Time %d | Zone %d | Possession team %d holder %s | Line team %d | Command %s (%d ticks)" % [
		s.chukker, max(0, s.time_remaining), s.ball.zone, s.ball.possession_team, s.ball.holder_id,
		s.ball.line_owner_team, GameSession.selected_command, s.command_ticks_remaining
	]
	riders_label.text = _rider_status_text(s)
	breakdown_label.text = _breakdown_text(s)
	break_panel.visible = s.substitution_pending or s.status == "between_chukkers"
	_move_ball_to_zone(s.ball.zone)

func _rider_status_text(s: MatchState) -> String:
	var parts: Array[String] = []
	for rider in s.riders:
		if int(rider["team"]) == 0:
			parts.append("%s %s S%d F%d" % [rider["id"], rider["role"], int(rider["stamina"]), int(rider["focus"])])
	return "Riders: %s" % " | ".join(parts)

func _breakdown_text(s: MatchState) -> String:
	var synergy_names: Array[String] = []
	for synergy in s.synergies.get(0, []):
		synergy_names.append(str(synergy["name"]))
	if s.dominance_breakdowns.is_empty():
		return "Synergies: %s" % (", ".join(synergy_names) if synergy_names.size() > 0 else "none")
	var latest: Dictionary = s.dominance_breakdowns[s.dominance_breakdowns.size() - 1]
	return "Synergies: %s | Last %s by %s: total %.1f, role %.2f, line %.1f, tactic %.1f, synergy %.1f" % [
		", ".join(synergy_names) if synergy_names.size() > 0 else "none",
		latest["action"], latest["rider"], float(latest["total"]), float(latest["role_fit"]),
		float(latest["line_owner_bonus"]), float(latest["tactic_bonus"]), float(latest["synergy_bonus"])
	]

func _apply_event_visual(event: MatchEvent) -> void:
	if event.type in ["BallAdvanced", "BallRetreated", "GoalScored", "BallRecovered", "SkillActivated"]:
		_move_ball_to_zone(int(event.payload.get("zone", GameSession.current_state.ball.zone)))

func _move_ball_to_zone(zone: int) -> void:
	if zone_nodes.is_empty():
		return
	var target := zone_nodes[clampi(zone - 1, 0, 4)]
	var center := target.global_position + target.size * 0.5 - ball.size * 0.5
	var tween := create_tween()
	tween.tween_property(ball, "global_position", center, 0.35 / display_speed)
