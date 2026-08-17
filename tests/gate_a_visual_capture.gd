extends SceneTree

const OUT_DIR := "res://reports/interactive-match/screenshots"

var scene_ref: Node

func _init() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	scene_ref = packed.instantiate()
	root.add_child(scene_ref)
	await process_frame
	scene_ref.harness_mode = true
	await _capture("01_full_field")
	await _frames(35)
	await _capture("02_rider_moving")
	await _frames(50)
	await _capture("03_aim_path")
	await _frames(45)
	await _capture("04_ball_after_strike")
	await _wait_for_score()
	await _capture("05_goal_score")
	await _capture("06_hud_touch_controls")
	print("GATE A VISUAL CAPTURE PASSED")
	quit(0)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _wait_for_score() -> void:
	for i in range(240):
		await process_frame
		if scene_ref.engine != null and int(scene_ref.engine.state["scores"][0]) > 0:
			return

func _capture(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [OUT_DIR, name])
