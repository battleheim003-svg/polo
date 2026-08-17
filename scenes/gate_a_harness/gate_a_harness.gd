extends Control

func _ready() -> void:
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	var scene: Control = packed.instantiate()
	scene.harness_mode = true
	scene.video_capture_mode = true
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scene)
