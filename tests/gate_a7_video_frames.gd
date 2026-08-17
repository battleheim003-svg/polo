extends SceneTree

const OUT_DIR := "res://reports/interactive-match/gate-a7-video-frames"

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
	await _frames(45)
	scene_ref.overview_time = 0.0
	for i in range(900):
		await process_frame
		_capture(i)
	print("GATE A7 VIDEO FRAMES PASSED")
	quit(0)

func _capture(index: int) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/frame_%04d.png" % [OUT_DIR, index])

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
