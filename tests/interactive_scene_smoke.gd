extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("INTERACTIVE SCENE SMOKE PASSED")
	quit(0)
