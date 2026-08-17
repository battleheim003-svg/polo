extends SceneTree

const OUT_DIR := "res://reports/interactive-match/video_frames"

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
	scene_ref.video_capture_mode = true
	for i in range(1260):
		await process_frame
		if i % 2 == 0:
			_capture(i / 2)
	print("GATE A VIDEO FRAMES PASSED")
	quit(0)

func _capture(index: int) -> void:
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("%s/frame_%04d.png" % [OUT_DIR, index])
