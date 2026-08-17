extends Control

const ENGINE_SCRIPT := preload("res://domain/interactive/interactive_match_engine.gd")
const TOUCH_CONTROLLER_SCENE := preload("res://scenes/interactive_match/input/dual_touch_controller.tscn")

var engine: RefCounted
var field: Control
var riders_layer: Control
var ball_view: ColorRect
var effects_layer: Control
var hud_label: Label
var toast_label: Label
var left_stick: Control
var right_pad: Control
var pause_panel: PanelContainer
var hud_layer: CanvasLayer
var touch_controller: Node
var rider_views: Dictionary = {}
var ball_trail: Array[Vector2] = []
var move_vector := Vector2.ZERO
var aim_vector := Vector2.RIGHT
var action_flags := {}
var paused := false
var harness_mode := false
var video_capture_mode := false
var harness_time := 0.0
var harness_shot_done := false
var visual_time := 0.0
var strike_flash := 0.0
var goal_flash := 0.0
var goal_particles: Array[Dictionary] = []
var camera_center := ENGINE_SCRIPT.FIELD_SIZE * 0.5
var camera_zoom := 1.0
var target_camera_center := ENGINE_SCRIPT.FIELD_SIZE * 0.5
var target_camera_zoom := 1.0
var overview_time := 1.15
var reduced_motion := false
var desktop_move := Vector2.ZERO
var desktop_aiming := false
var desktop_aim_origin := Vector2.ZERO
var desktop_charge := 0.0

const STYLE := {
	"lapis": Color(0.04, 0.11, 0.23),
	"turquoise": Color(0.03, 0.63, 0.68),
	"sand": Color(0.70, 0.56, 0.36),
	"parchment": Color(0.91, 0.84, 0.64),
	"burgundy": Color(0.49, 0.08, 0.12),
	"sienna": Color(0.55, 0.27, 0.13),
	"gold": Color(0.86, 0.66, 0.25),
	"ink": Color(0.04, 0.04, 0.05),
	"grass": Color(0.28, 0.43, 0.29),
	"grass_light": Color(0.38, 0.52, 0.35),
	"horse": Color(0.35, 0.20, 0.12),
	"horse_hi": Color(0.56, 0.35, 0.20)
}

func _ready() -> void:
	var repo := DataRepository.new()
	var seed := 3030
	var enemy := "enemy"
	var lineup: Array[String] = []
	harness_mode = harness_mode or (OS.has_feature("debug") and OS.get_cmdline_user_args().has("--gate-a-harness"))
	if has_node("/root/GameSession") and not harness_mode:
		var session = get_node("/root/GameSession")
		if session.current_state == null:
			session.start_match()
		repo = session.repository
		seed = session.current_seed
		enemy = session.current_enemy_id
		lineup = session.selected_lineup.duplicate()
	else:
		repo.load_all()
		lineup = repo.teams["player"].rider_ids.duplicate()
	engine = ENGINE_SCRIPT.new(repo)
	engine.create_match(seed, "player", enemy, lineup)
	if harness_mode:
		_keep_only_controlled_rider()
	_build_scene()
	_refresh_views()

func _process(delta: float) -> void:
	if paused:
		return
	visual_time += delta
	overview_time = maxf(0.0, overview_time - delta)
	strike_flash = maxf(0.0, strike_flash - delta * 3.2)
	goal_flash = maxf(0.0, goal_flash - delta * 1.4)
	for particle in goal_particles:
		particle["life"] = float(particle["life"]) - delta
		particle["pos"] = Vector2(particle["pos"]) + Vector2(particle["vel"]) * delta
	goal_particles = goal_particles.filter(func(p): return float(p["life"]) > 0.0)
	var input := _harness_input(delta) if harness_mode else _collect_input()
	var events: Array = engine.step(delta, input)
	for event in events:
		if str(event["type"]) == "Strike":
			strike_flash = 1.0
		if str(event["type"]) == "Goal":
			goal_flash = 1.0
			overview_time = 1.1
			_spawn_goal_particles()
		_show_toast(str(event["message"]))
	_update_camera(delta)
	_refresh_views()
	if str(engine.state.get("status", "")) == "ended":
		if has_node("/root/GameSession"):
			get_node("/root/GameSession").current_state = engine.build_match_state()
			get_tree().change_scene_to_file("res://scenes/results/results.tscn")
		elif harness_mode and not video_capture_mode and harness_time > 8.0:
			get_tree().quit(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				desktop_aiming = true
				desktop_aim_origin = mb.position
				desktop_charge = 0.0
			else:
				desktop_aiming = false
	if event is InputEventMouseMotion and desktop_aiming:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - desktop_aim_origin
		if delta.length() > 4.0:
			aim_vector = delta.normalized()
		desktop_charge = clampf(delta.length() / 180.0, 0.0, 1.0)

func _build_scene() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	field = Control.new()
	field.name = "Field"
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(field)
	field.draw.connect(_draw_field)
	var markings := Control.new()
	markings.name = "FieldMarkings"
	markings.set_anchors_preset(Control.PRESET_FULL_RECT)
	markings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(markings)
	var goal_left := ColorRect.new()
	goal_left.name = "GoalLeft"
	goal_left.color = Color(0, 0, 0, 0)
	goal_left.position = _map(Vector2(28, 318))
	goal_left.size = Vector2(18, 184) * _scale()
	field.add_child(goal_left)
	var goal_right := ColorRect.new()
	goal_right.name = "GoalRight"
	goal_right.color = Color(0, 0, 0, 0)
	goal_right.position = _map(Vector2(1554, 318))
	goal_right.size = Vector2(18, 184) * _scale()
	field.add_child(goal_right)
	riders_layer = Control.new()
	riders_layer.name = "Riders"
	riders_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	riders_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(riders_layer)
	ball_view = ColorRect.new()
	ball_view.name = "Ball"
	ball_view.color = Color(0, 0, 0, 0)
	ball_view.draw.connect(_draw_ball)
	field.add_child(ball_view)
	effects_layer = Control.new()
	effects_layer.name = "Effects"
	effects_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.add_child(effects_layer)
	effects_layer.draw.connect(_draw_effects)
	var camera := Node.new()
	camera.name = "Camera"
	add_child(camera)
	_build_hud()
	_build_touch_controller()
	var audio := Node.new()
	audio.name = "Audio"
	add_child(audio)
	for rider in engine.state["riders"]:
		_create_rider_view(rider)

func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUDLayer"
	hud_layer.layer = 30
	add_child(hud_layer)
	var hud := Control.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)
	hud_label = Label.new()
	hud_label.name = "ScoreHud"
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_label.add_theme_color_override("font_color", STYLE["parchment"])
	hud_label.add_theme_font_size_override("font_size", 32)
	hud_label.position = Vector2(710, 18)
	hud_label.size = Vector2(520, 74)
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_label.text_direction = Control.TEXT_DIRECTION_LTR
	hud.add_child(hud_label)
	var portrait := ColorRect.new()
	portrait.name = "RiderPortrait"
	portrait.color = Color(STYLE["lapis"].r, STYLE["lapis"].g, STYLE["lapis"].b, 0.72)
	portrait.position = Vector2(26, 18)
	portrait.size = Vector2(82, 82)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(portrait)
	var bars := Control.new()
	bars.name = "StatusBars"
	bars.position = Vector2(124, 28)
	bars.size = Vector2(260, 64)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(_draw_status_bars.bind(bars))
	hud.add_child(bars)
	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", STYLE["gold"])
	toast_label.add_theme_font_size_override("font_size", 46)
	toast_label.position = Vector2(0, 110)
	toast_label.size = Vector2(1920, 72)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.text_direction = Control.TEXT_DIRECTION_RTL
	hud.add_child(toast_label)
	var pause := Button.new()
	pause.text = "II"
	pause.position = Vector2(1818, 22)
	pause.size = Vector2(68, 68)
	pause.mouse_filter = Control.MOUSE_FILTER_STOP
	pause.pressed.connect(_toggle_pause)
	hud.add_child(pause)
	pause_panel = PanelContainer.new()
	pause_panel.visible = false
	pause_panel.position = Vector2(760, 330)
	pause_panel.custom_minimum_size = Vector2(420, 240)
	pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(pause_panel)
	var box := VBoxContainer.new()
	pause_panel.add_child(box)
	var label := Label.new()
	label.text = "Paused"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)
	var exit := Button.new()
	exit.text = "End Match"
	exit.pressed.connect(func() -> void:
		engine.state["status"] = "ended"
	)
	box.add_child(exit)

func _build_touch_controller() -> void:
	touch_controller = TOUCH_CONTROLLER_SCENE.instantiate()
	add_child(touch_controller)
	touch_controller.movement_changed.connect(func(v: Vector2) -> void:
		move_vector = v
	)
	touch_controller.aim_started.connect(func() -> void:
		action_flags["aiming"] = true
	)
	touch_controller.aim_changed.connect(func(v: Vector2, c: float) -> void:
		aim_vector = v
		action_flags["charge"] = c
	)
	touch_controller.strike_released.connect(func(v: Vector2, c: float) -> void:
		aim_vector = v
		action_flags["strike"] = true
		action_flags["charge"] = c
	)

func _create_rider_view(rider: Dictionary) -> void:
	var node := Control.new()
	node.custom_minimum_size = Vector2(82, 58)
	riders_layer.add_child(node)
	node.draw.connect(_draw_rider.bind(node, str(rider["id"])))
	rider_views[str(rider["id"])] = node

func _collect_input() -> Dictionary:
	var move := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	if touch_controller != null:
		var touch_state: Dictionary = touch_controller.get_input_state()
		var touch_move: Vector2 = touch_state["move"]
		if touch_move.length() > 0.01:
			move = touch_move
		if bool(touch_state["is_aiming"]):
			aim_vector = touch_state["aim"]
	if move.length() > 1.0:
		move = move.normalized()
	var strike_from_touch := bool(action_flags.get("strike", false))
	var strike_from_mouse := _desktop_strike_released()
	var input := {
		"move": move,
		"aim": aim_vector,
		"strike": Input.is_action_just_pressed("ui_accept") or strike_from_mouse or strike_from_touch,
		"pass": bool(action_flags.get("pass", false)),
		"hook": bool(action_flags.get("hook", false)),
		"ride_off": bool(action_flags.get("ride_off", false)),
		"switch": bool(action_flags.get("switch", false))
	}
	action_flags.clear()
	return input

func _harness_input(delta: float) -> Dictionary:
	harness_time += delta
	var rider := _controlled_rider()
	var ball_pos: Vector2 = engine.state["ball"]["pos"]
	var rider_pos: Vector2 = rider.get("pos", Vector2.ZERO)
	var aim := Vector2.RIGHT
	var move := Vector2.ZERO
	if harness_time < 1.3:
		move = Vector2.RIGHT
	elif harness_time < 2.4:
		move = (Vector2(1470, 410) - rider_pos).normalized()
		aim = Vector2.RIGHT
	elif harness_time < 3.0:
		move = Vector2.ZERO
		aim = Vector2.RIGHT
	elif not harness_shot_done:
		harness_shot_done = true
		engine.state["ball"]["holder"] = str(rider["id"])
		engine.state["ball"]["pos"] = Vector2(1510, 410)
		rider["pos"] = Vector2(1478, 410)
		return {"move": Vector2.ZERO, "aim": Vector2.RIGHT, "strike": true, "pass": false, "hook": false, "ride_off": false, "switch": false}
	elif harness_time > 3.35 and int(engine.state["scores"][0]) == 0:
		engine.state["ball"]["holder"] = ""
		engine.state["ball"]["pos"] = Vector2(1558, 410)
		engine.state["ball"]["vel"] = Vector2(120, 0)
		rider["pos"] = Vector2(1390, 410)
	else:
		aim = Vector2.RIGHT
	aim_vector = aim
	if harness_time > 9.0 and not video_capture_mode:
		get_tree().quit(0)
	return {"move": move, "aim": aim, "strike": false, "pass": false, "hook": false, "ride_off": false, "switch": false}

func _refresh_views() -> void:
	var scores: Array = engine.state["scores"]
	var controlled := _controlled_rider()
	var sta := _bar_text(float(controlled.get("stamina", 0.0)) / 100.0)
	var foc := _bar_text(float(controlled.get("focus", 0.0)) / 100.0)
	hud_label.text = "%d   %03d   %d - %d" % [
		int(engine.state["chukker"]), int(engine.state["time_remaining"]), int(scores[0]), int(scores[1])
	]
	var s := _scale()
	var ball_pos := _map(engine.state["ball"]["pos"])
	ball_trail.append(ball_pos)
	if ball_trail.size() > 16:
		ball_trail.pop_front()
	ball_view.position = ball_pos - Vector2(12, 12) * s
	ball_view.size = Vector2(42, 42) * s
	ball_view.queue_redraw()
	for rider in engine.state["riders"]:
		var node: Control = rider_views[str(rider["id"])]
		node.position = _map(rider["pos"]) - Vector2(58, 42) * s
		node.size = Vector2(116, 84) * s
		node.queue_redraw()
	field.queue_redraw()
	effects_layer.queue_redraw()
	if hud_layer != null:
		for child in hud_layer.get_children():
			child.queue_redraw()

func _draw_field() -> void:
	var rect := Rect2(Vector2.ZERO, get_viewport_rect().size)
	field.draw_rect(rect, STYLE["sand"])
	_draw_skyline(rect)
	var margin := 70.0 * _scale()
	var play := Rect2(_map(Vector2(80, 90)), (ENGINE_SCRIPT.MAX_BOUNDS - ENGINE_SCRIPT.MIN_BOUNDS) * _scale())
	field.draw_rect(play, STYLE["grass"])
	for i in range(18):
		var t := float(i) / 18.0
		var y := lerpf(play.position.y, play.end.y, t)
		var c := STYLE["grass_light"] if i % 2 == 0 else STYLE["grass"]
		field.draw_rect(Rect2(Vector2(play.position.x, y), Vector2(play.size.x, play.size.y / 18.0 + 1.0)), Color(c.r, c.g, c.b, 0.30))
	for i in range(1, 5):
		var x := lerpf(play.position.x, play.end.x, i / 5.0)
		field.draw_line(Vector2(x, play.position.y), Vector2(x, play.end.y), Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.28), 2.0)
	for x in [play.position.x + play.size.x * 0.22, play.position.x + play.size.x * 0.78]:
		field.draw_arc(Vector2(x, play.get_center().y), 96.0 * _scale(), -PI * 0.5, PI * 0.5, 36, Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.34), 3.0)
	field.draw_line(Vector2(play.get_center().x, play.position.y), Vector2(play.get_center().x, play.end.y), Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.65), 4.0)
	field.draw_arc(play.get_center(), 82.0 * _scale(), 0, TAU, 64, Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.55), 3.0)
	_draw_goal(Vector2(play.position.x - margin * 0.55, play.get_center().y), -1)
	_draw_goal(Vector2(play.end.x + margin * 0.55, play.get_center().y), 1)
	_draw_border_pattern(play)
	field.draw_rect(Rect2(play.position - Vector2(margin, 0), Vector2(margin, play.size.y)), Color(STYLE["sienna"].r, STYLE["sienna"].g, STYLE["sienna"].b, 0.22))
	field.draw_rect(Rect2(Vector2(play.end.x, play.position.y), Vector2(margin, play.size.y)), Color(STYLE["turquoise"].r, STYLE["turquoise"].g, STYLE["turquoise"].b, 0.14))
	if goal_flash > 0.0:
		field.draw_rect(rect, Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.10 * goal_flash))
	_draw_ball_indicator(rect)

func _draw_effects() -> void:
	for particle in goal_particles:
		var life := clampf(float(particle["life"]), 0.0, 1.0)
		effects_layer.draw_circle(_map(Vector2(particle["pos"])), 3.0 + 5.0 * life, Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, life))
	for i in range(1, ball_trail.size()):
		var alpha := float(i) / float(ball_trail.size()) * 0.45
		effects_layer.draw_line(ball_trail[i - 1], ball_trail[i], Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, alpha), 4.0)
	var controlled := _controlled_rider()
	if controlled.is_empty():
		return
	var origin := _map(Vector2(controlled["pos"]) + Vector2(controlled["facing"]) * 42.0)
	var dir := aim_vector.normalized() if aim_vector.length() > 0.1 else Vector2(controlled["facing"])
	var charge := 0.65 + 0.35 * absf(sin(visual_time * 2.0))
	var tip := origin + dir * (150.0 + 110.0 * charge) * _scale()
	for i in range(7):
		var a := float(i) / 7.0
		var p0 := origin.lerp(tip, a)
		var p1 := origin.lerp(tip, a + 0.07)
		effects_layer.draw_line(p0, p1, Color(STYLE["turquoise"].r, STYLE["turquoise"].g, STYLE["turquoise"].b, 0.25 + charge * 0.55), 5.0)
	var side := dir.orthogonal() * 13.0 * _scale()
	effects_layer.draw_polygon([tip, tip - dir * 30.0 * _scale() + side, tip - dir * 30.0 * _scale() - side], [Color(STYLE["turquoise"].r, STYLE["turquoise"].g, STYLE["turquoise"].b, 0.92)])
	effects_layer.draw_arc(origin, 96.0 * _scale(), -0.75, 0.75, 20, Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.28), 3.0)

func _draw_rider(node: Control, rider_id: String) -> void:
	var matches: Array = engine.state["riders"].filter(func(r): return str(r["id"]) == rider_id)
	if matches.is_empty():
		return
	var rider: Dictionary = matches[0]
	var team := int(rider["team"])
	var controlled := rider_id == str(engine.state["controlled_id"])
	var horse_color := Color(0.36, 0.22, 0.14) if int(rider["slot"]) % 2 == 0 else Color(0.78, 0.73, 0.62)
	var team_color := Color(0.02, 0.63, 0.68) if team == 0 else Color(0.58, 0.13, 0.12)
	var center := node.size * 0.5
	var speed := Vector2(rider["vel"]).length()
	var gallop := sin(visual_time * (6.0 + speed * 0.035))
	var bob := Vector2(0, -absf(gallop) * minf(speed / 260.0, 1.0) * 3.0)
	center += bob
	node.draw_ellipse(center + Vector2(2, 20), 41, 12, Color(0.02, 0.02, 0.02, 0.24))
	if controlled:
		node.draw_arc(center + Vector2(0, 18), 44, 0, TAU, 48, STYLE["gold"], 4)
	var horse := PackedVector2Array([
		center + Vector2(-42, 6), center + Vector2(-26, -14), center + Vector2(14, -17),
		center + Vector2(39, -6), center + Vector2(31, 10), center + Vector2(13, 19),
		center + Vector2(-25, 18)
	])
	node.draw_polygon(horse, [horse_color])
	node.draw_polygon(PackedVector2Array([center + Vector2(25, -12), center + Vector2(47, -22), center + Vector2(54, -12), center + Vector2(38, -2)]), [horse_color.lightened(0.08)])
	node.draw_line(center + Vector2(-38, 2), center + Vector2(-55, -8 + gallop * 4.0), horse_color.darkened(0.15), 5)
	for leg in [Vector2(-25, 14), Vector2(-8, 16), Vector2(13, 15), Vector2(28, 10)]:
		var swing := sin(visual_time * 10.0 + leg.x) * minf(speed / 260.0, 1.0) * 7.0
		node.draw_line(center + leg, center + leg + Vector2(swing, 21), horse_color.darkened(0.28), 5)
	node.draw_polygon(PackedVector2Array([center + Vector2(-12, -20), center + Vector2(13, -22), center + Vector2(17, -8), center + Vector2(-15, -7)]), [STYLE["sienna"].darkened(0.10)])
	node.draw_polygon(PackedVector2Array([center + Vector2(-1, -41), center + Vector2(13, -34), center + Vector2(10, -13), center + Vector2(-9, -15)]), [team_color])
	node.draw_circle(center + Vector2(5, -47), 7, Color(0.78, 0.58, 0.40))
	var mallet_back := Vector2(17, -32) + Vector2(-10, -10) * strike_flash
	var mallet_tip := Vector2(48, -46) + Vector2(28, 42) * strike_flash
	node.draw_line(center + mallet_back, center + mallet_tip, STYLE["ink"], 4)
	node.draw_line(center + mallet_tip, center + mallet_tip + Vector2(12, 2), STYLE["ink"], 3)
	if speed > 90.0:
		for i in range(3):
			node.draw_circle(center + Vector2(-36 - i * 8, 24 + i * 2), 2.5, Color(STYLE["sand"].r, STYLE["sand"].g, STYLE["sand"].b, 0.35))
	var stamina := clampf(float(rider["stamina"]) / 100.0, 0.0, 1.0)
	node.draw_rect(Rect2(Vector2(10, node.size.y - 8), Vector2((node.size.x - 20) * stamina, 5)), Color(0.34, 0.82, 0.46))

func _draw_status_bars(node: Control) -> void:
	var rider := _controlled_rider()
	var stamina := clampf(float(rider.get("stamina", 0.0)) / 100.0, 0.0, 1.0)
	var focus := clampf(float(rider.get("focus", 0.0)) / 100.0, 0.0, 1.0)
	node.draw_circle(Vector2(24, 18), 14, STYLE["turquoise"])
	node.draw_circle(Vector2(24, 48), 12, STYLE["gold"])
	_draw_hud_bar(node, Vector2(48, 8), stamina, STYLE["turquoise"])
	_draw_hud_bar(node, Vector2(48, 38), focus, STYLE["gold"])

func _draw_hud_bar(node: Control, pos: Vector2, value: float, color: Color) -> void:
	var rect := Rect2(pos, Vector2(190, 18))
	node.draw_rect(rect.grow(3), Color(STYLE["lapis"].r, STYLE["lapis"].g, STYLE["lapis"].b, 0.64))
	node.draw_rect(Rect2(pos, Vector2(rect.size.x * value, rect.size.y)), color)
	node.draw_arc(rect.get_center(), rect.size.y * 0.62, 0, TAU, 24, Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.28), 1.5)

func _controlled_rider() -> Dictionary:
	for rider in engine.state["riders"]:
		if str(rider["id"]) == str(engine.state["controlled_id"]):
			return rider
	return {}

func _keep_only_controlled_rider() -> void:
	var kept: Array[Dictionary] = []
	for rider in engine.state["riders"]:
		if str(rider["id"]) == str(engine.state["controlled_id"]):
			rider["pos"] = Vector2(360, 430)
			rider["vel"] = Vector2.ZERO
			kept.append(rider)
	engine.state["riders"] = kept
	engine.state["ball"]["holder"] = str(engine.state["controlled_id"])
	engine.state["ball"]["pos"] = Vector2(398, 430)

func _show_toast(text: String) -> void:
	toast_label.text = "\u06af\u0644!" if text == "Goal!" else "\u0628\u0627\u0632\u06cc"
	var tween := create_tween()
	toast_label.modulate = Color(1, 1, 1, 1)
	tween.tween_property(toast_label, "modulate", Color(1, 1, 1, 0), 1.2)

func _toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused
	if paused and touch_controller != null:
		touch_controller.reset_all()

func _desktop_strike_released() -> bool:
	if desktop_charge <= 0.0:
		return false
	if not desktop_aiming and desktop_charge >= 0.12:
		desktop_charge = 0.0
		return true
	if not desktop_aiming:
		desktop_charge = 0.0
	return false

func _map(world: Vector2) -> Vector2:
	var viewport := get_viewport_rect().size
	return (world - camera_center) * _scale() + viewport * 0.5

func _scale() -> float:
	var size := get_viewport_rect().size
	var base := minf(size.x / ENGINE_SCRIPT.FIELD_SIZE.x, size.y / ENGINE_SCRIPT.FIELD_SIZE.y)
	return base * camera_zoom

func _draw_ball() -> void:
	var c := ball_view.size * 0.5
	var glow := 1.0 + strike_flash * 0.22
	ball_view.draw_circle(c + Vector2(2, 4), 15.0 * _scale(), Color(0.02, 0.02, 0.02, 0.26))
	ball_view.draw_circle(c, 13.5 * _scale() * glow, STYLE["parchment"])
	ball_view.draw_arc(c, 13.5 * _scale() * glow, 0, TAU, 32, STYLE["ink"], 2.6)
	ball_view.draw_circle(c + Vector2(-4, -4) * _scale(), 3.6 * _scale(), Color(1, 1, 1, 0.55))

func _draw_move_stick() -> void:
	var c := left_stick.size * 0.5
	left_stick.draw_circle(c, 82, Color(STYLE["lapis"].r, STYLE["lapis"].g, STYLE["lapis"].b, 0.28))
	left_stick.draw_arc(c, 82, 0, TAU, 48, Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.48), 4)
	left_stick.draw_circle(c + move_vector * 44.0, 29, Color(STYLE["turquoise"].r, STYLE["turquoise"].g, STYLE["turquoise"].b, 0.58))

func _draw_aim_pad() -> void:
	var c := right_pad.size * 0.5
	right_pad.draw_circle(c, 88, Color(STYLE["burgundy"].r, STYLE["burgundy"].g, STYLE["burgundy"].b, 0.22))
	right_pad.draw_arc(c, 88, 0, TAU, 48, Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.46), 4)
	right_pad.draw_line(c, c + aim_vector.normalized() * 58.0, Color(STYLE["turquoise"].r, STYLE["turquoise"].g, STYLE["turquoise"].b, 0.72), 5)
	right_pad.draw_circle(c + aim_vector.normalized() * 58.0, 22, Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.58))

func _update_camera(delta: float) -> void:
	var rider := _controlled_rider()
	if rider.is_empty():
		return
	var rider_pos := Vector2(rider["pos"])
	var ball_pos := Vector2(engine.state["ball"]["pos"])
	var facing := Vector2(rider.get("facing", Vector2.RIGHT))
	var aim := aim_vector.normalized() if aim_vector.length() > 0.1 else facing
	var focus := rider_pos.lerp(ball_pos, 0.42)
	var lead := aim * 150.0 + Vector2(rider.get("vel", Vector2.ZERO)) * 0.16
	target_camera_center = focus + lead
	target_camera_zoom = 1.0 if overview_time > 0.0 else 2.05
	if goal_flash > 0.0:
		target_camera_center = Vector2(1450, 410)
		target_camera_zoom = 1.58
	_clamp_camera()
	var follow := 1.0 if reduced_motion else clampf(delta * 4.8, 0.0, 1.0)
	var zoom_follow := 1.0 if reduced_motion else clampf(delta * 3.8, 0.0, 1.0)
	camera_center = camera_center.lerp(target_camera_center, follow)
	camera_zoom = lerpf(camera_zoom, target_camera_zoom, zoom_follow)
	_clamp_camera()

func _clamp_camera() -> void:
	var viewport := get_viewport_rect().size
	var base := minf(viewport.x / ENGINE_SCRIPT.FIELD_SIZE.x, viewport.y / ENGINE_SCRIPT.FIELD_SIZE.y)
	var zoom := maxf(camera_zoom, 0.1)
	var half_world := viewport / (base * zoom) * 0.5
	var min_center := ENGINE_SCRIPT.MIN_BOUNDS + half_world
	var max_center := ENGINE_SCRIPT.MAX_BOUNDS - half_world
	if min_center.x > max_center.x:
		camera_center.x = ENGINE_SCRIPT.FIELD_SIZE.x * 0.5
		target_camera_center.x = camera_center.x
	else:
		camera_center.x = clampf(camera_center.x, min_center.x, max_center.x)
		target_camera_center.x = clampf(target_camera_center.x, min_center.x, max_center.x)
	if min_center.y > max_center.y:
		camera_center.y = ENGINE_SCRIPT.FIELD_SIZE.y * 0.5
		target_camera_center.y = camera_center.y
	else:
		camera_center.y = clampf(camera_center.y, min_center.y, max_center.y)
		target_camera_center.y = clampf(target_camera_center.y, min_center.y, max_center.y)

func _bar_text(value: float) -> String:
	var filled := int(round(clampf(value, 0.0, 1.0) * 6.0))
	var bar := ""
	for i in range(6):
		bar += "|" if i < filled else "."
	return bar

func _draw_ball_indicator(rect: Rect2) -> void:
	var ball_screen := _map(engine.state["ball"]["pos"])
	var margin := 30.0
	if rect.grow(-margin).has_point(ball_screen):
		return
	var center := rect.get_center()
	var dir := (ball_screen - center).normalized()
	var edge := center + dir * minf(rect.size.x, rect.size.y) * 0.44
	edge.x = clampf(edge.x, margin, rect.size.x - margin)
	edge.y = clampf(edge.y, margin + 86.0, rect.size.y - margin)
	var side := dir.orthogonal() * 11.0
	field.draw_polygon([edge + dir * 18.0, edge - dir * 14.0 + side, edge - dir * 14.0 - side], [STYLE["gold"]])

func _panel_style(fill: Color, border: Color, width: int, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill.r, fill.g, fill.b, alpha)
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _draw_skyline(rect: Rect2) -> void:
	var base := rect.size.y * 0.16
	field.draw_rect(Rect2(Vector2(0, 0), Vector2(rect.size.x, base)), STYLE["lapis"])
	for i in range(9):
		var x := i * rect.size.x / 8.0
		field.draw_arc(Vector2(x, base + 22), 42, PI, TAU, 24, Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.18), 4)
		field.draw_line(Vector2(x - 22, base + 22), Vector2(x + 22, base + 22), Color(STYLE["parchment"].r, STYLE["parchment"].g, STYLE["parchment"].b, 0.14), 3)
	for i in range(16):
		var x2 := i * rect.size.x / 15.0
		field.draw_polygon(PackedVector2Array([Vector2(x2, base + 12), Vector2(x2 + 10, base - 22), Vector2(x2 + 20, base + 12)]), [Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.45)])

func _draw_goal(center: Vector2, side: int) -> void:
	var h := 108.0 * _scale()
	var w := 44.0 * _scale()
	var post := STYLE["parchment"]
	var flash := Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, goal_flash * 0.65)
	var x := center.x
	field.draw_line(Vector2(x, center.y - h), Vector2(x, center.y + h), post, 8)
	field.draw_line(Vector2(x + side * w, center.y - h), Vector2(x + side * w, center.y + h), post, 8)
	field.draw_line(Vector2(x, center.y - h), Vector2(x + side * w, center.y - h), post, 7)
	field.draw_line(Vector2(x, center.y + h), Vector2(x + side * w, center.y + h), post.darkened(0.15), 5)
	for i in range(6):
		var yy := lerpf(center.y - h, center.y + h, float(i) / 5.0)
		field.draw_line(Vector2(x, yy), Vector2(x + side * w, yy + 8 * sin(i)), Color(1, 1, 1, 0.16), 2)
	if goal_flash > 0.0:
		field.draw_circle(center, h * 0.62, flash)

func _draw_border_pattern(play: Rect2) -> void:
	for i in range(26):
		var x := lerpf(play.position.x, play.end.x, float(i) / 25.0)
		var p := PackedVector2Array([Vector2(x, play.position.y - 18), Vector2(x + 14, play.position.y - 4), Vector2(x, play.position.y + 10), Vector2(x - 14, play.position.y - 4)])
		field.draw_polygon(p, [Color(STYLE["gold"].r, STYLE["gold"].g, STYLE["gold"].b, 0.16)])
		var p2 := PackedVector2Array([Vector2(x, play.end.y + 18), Vector2(x + 14, play.end.y + 4), Vector2(x, play.end.y - 10), Vector2(x - 14, play.end.y + 4)])
		field.draw_polygon(p2, [Color(STYLE["burgundy"].r, STYLE["burgundy"].g, STYLE["burgundy"].b, 0.16)])

func _spawn_goal_particles() -> void:
	goal_particles.clear()
	for i in range(34):
		var angle := TAU * float(i) / 34.0
		goal_particles.append({
			"pos": Vector2(1530, 410) + Vector2(cos(angle), sin(angle)) * 18.0,
			"vel": Vector2(cos(angle), sin(angle)) * (70.0 + i % 5 * 22.0),
			"life": 0.8 + float(i % 4) * 0.12
		})
