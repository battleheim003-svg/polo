extends SceneTree

const OUT_DIR := "res://reports/interactive-match/gate-a8"

var scene_ref: Node

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	scene_ref = packed.instantiate()
	scene_ref.harness_mode = true
	scene_ref.video_capture_mode = true
	root.add_child(scene_ref)
	await process_frame
	await _frames(8)
	await _capture("01_normal_hud")
	await _capture("02_joystick_idle")
	_touch_move(true)
	await _frames(22)
	await _capture("03_joystick_active")
	_touch_aim(true)
	await _frames(28)
	await _capture("04_aim_charge")
	await _capture("05_simultaneous_move_aim")
	_touch_aim(false)
	await _frames(22)
	await _capture("06_strike_release")
	await _wait_for_score()
	await _capture("07_persian_goal")
	print("GATE A8 VISUAL CAPTURE PASSED")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _capture(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])

func _wait_for_score() -> void:
	for i in range(260):
		await process_frame
		if scene_ref.engine != null and int(scene_ref.engine.state["scores"][0]) > 0:
			return

func _touch_move(pressed: bool) -> void:
	var c: Node = scene_ref.touch_controller
	var center: Vector2 = c.joystick_center
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = center
	e.pressed = pressed
	c._input(e)
	if pressed:
		var d := InputEventScreenDrag.new()
		d.index = 0
		d.position = center + Vector2(c.joystick_radius * 0.85, -c.joystick_radius * 0.15)
		c._input(d)

func _touch_aim(pressed: bool) -> void:
	var c: Node = scene_ref.touch_controller
	var size := root.get_viewport().get_visible_rect().size
	var start := Vector2(size.x * 0.74, size.y * 0.76)
	var end := start + Vector2(240, -120)
	var e := InputEventScreenTouch.new()
	e.index = 1
	e.position = end if not pressed else start
	e.pressed = pressed
	c._input(e)
	if pressed:
		var d := InputEventScreenDrag.new()
		d.index = 1
		d.position = end
		c._input(d)
