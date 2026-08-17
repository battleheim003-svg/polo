extends SceneTree

func _init() -> void:
	var packed := load("res://scenes/interactive_match/interactive_match.tscn")
	var scene: Node = packed.instantiate()
	scene.harness_mode = true
	root.add_child(scene)
	await process_frame
	for i in range(180):
		await process_frame
	var rider: Dictionary = scene._controlled_rider()
	var rider_screen: Vector2 = scene._map(rider["pos"])
	var ball_screen: Vector2 = scene._map(scene.engine.state["ball"]["pos"])
	var viewport := root.get_viewport().get_visible_rect()
	assert(viewport.has_point(rider_screen), "camera keeps rider in frame")
	assert(viewport.grow(48).has_point(ball_screen), "camera keeps ball near frame")
	assert(scene.camera_zoom > 1.4, "camera zooms in after overview")
	scene.reduced_motion = true
	await process_frame
	assert(scene.reduced_motion, "reduce motion flag accepted")
	print("GATE A7 CAMERA READABILITY TEST PASSED")
	quit(0)
