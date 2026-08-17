extends SceneTree

const OUT_DIR := "res://reports/interactive-match/gate-a8-video-frames"

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
	for i in range(720):
		await process_frame
		if i == 60:
			_touch_move(true)
		if i == 160:
			_touch_aim(true)
		if i == 260:
			_touch_aim(false)
		if i == 430:
			_touch_move(false)
		_capture(i)
	print("GATE A8 VIDEO FRAMES PASSED")
	quit(0)

func _capture(index: int) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/frame_%04d.png" % [OUT_DIR, index])

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
		d.position = center + Vector2(c.joystick_radius * 0.82, -c.joystick_radius * 0.12)
		c._input(d)

func _touch_aim(pressed: bool) -> void:
	var c: Node = scene_ref.touch_controller
	var size := root.get_viewport().get_visible_rect().size
	var start := Vector2(size.x * 0.74, size.y * 0.76)
	var end := start + Vector2(240, -130)
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
