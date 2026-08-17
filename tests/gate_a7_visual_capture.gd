extends SceneTree

const OUT_DIR := "res://reports/interactive-match/gate-a7"

var scene_ref: Node

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	scene_ref = packed.instantiate()
	scene_ref.harness_mode = true
	root.add_child(scene_ref)
	await process_frame
	await _frames(5)
	await _capture("01_overview_start")
	scene_ref.overview_time = 0.0
	await _frames(55)
	await _capture("02_camera_follow")
	await _frames(34)
	await _capture("03_rider_scale_gallop")
	await _frames(35)
	await _capture("04_aim_charge_readable")
	await _frames(28)
	await _capture("05_strike_pose")
	await _frames(20)
	await _capture("06_ball_follow")
	await _wait_for_score()
	await _capture("07_goal_camera_feedback")
	ProjectSettings.set_setting("display/window/size/viewport_width", 2400)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	await _frames(12)
	await _capture("08_mobile_20x9_hud")
	print("GATE A7 VISUAL CAPTURE PASSED")
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
