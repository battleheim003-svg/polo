extends SceneTree

const OUT_DIR := "res://reports/interactive-match/gate-a6"

var scene_ref: Node

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	scene_ref = packed.instantiate()
	scene_ref.harness_mode = true
	root.add_child(scene_ref)
	await process_frame
	await _frames(8)
	await _capture("01_field")
	await _capture("02_rider_idle")
	await _frames(38)
	await _capture("03_rider_gallop")
	await _frames(54)
	await _capture("04_aim_charge")
	await _frames(32)
	await _capture("05_strike_impact")
	await _frames(28)
	await _capture("06_ball_motion")
	await _wait_for_score()
	await _capture("07_goal_feedback")
	await _capture("08_touch_hud")
	print("GATE A6 VISUAL CAPTURE PASSED")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _wait_for_score() -> void:
	for i in range(260):
		await process_frame
		if scene_ref.engine != null and int(scene_ref.engine.state["scores"][0]) > 0:
			return

func _capture(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])
