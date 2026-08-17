extends SceneTree

const ENGINE_SCRIPT := preload("res://domain/interactive/interactive_match_engine.gd")

var failures: Array[String] = []

func _init() -> void:
	var repo := DataRepository.new()
	_check(repo.load_all(), "data loads")
	var engine: RefCounted = ENGINE_SCRIPT.new(repo)
	var lineup: Array[String] = repo.teams["player"].rider_ids.duplicate()
	var state: Dictionary = engine.create_match(3030, "player", "enemy", lineup)
	_check(state["riders"].size() == 8, "spawns eight riders")
	_check(str(state["controlled_id"]) != "", "has controlled rider")
	_test_movement(engine)
	_test_ball_and_goal(engine)
	_test_result_bridge(engine)
	if failures.is_empty():
		print("INTERACTIVE TESTS PASSED: 10 checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _test_movement(engine: RefCounted) -> void:
	var rider := _controlled(engine)
	var before: Vector2 = rider["pos"]
	var stamina_before := float(rider["stamina"])
	for i in range(20):
		engine.step(0.016, {"move": Vector2.RIGHT, "aim": Vector2.RIGHT})
	var after: Vector2 = _controlled(engine)["pos"]
	_check(after.x > before.x, "controlled rider moves right")
	_check(after.x <= ENGINE_SCRIPT.MAX_BOUNDS.x, "rider remains in bounds")
	_check(float(_controlled(engine)["stamina"]) < stamina_before, "movement drains stamina")

func _test_ball_and_goal(engine: RefCounted) -> void:
	var rider := _controlled(engine)
	engine.state["ball"]["holder"] = str(rider["id"])
	rider["pos"] = Vector2(1450, 410)
	engine.step(0.016, {"move": Vector2.ZERO, "aim": Vector2.RIGHT, "strike": true})
	_check(str(engine.state["ball"]["holder"]) == "", "strike releases ball")
	engine.state["ball"]["holder"] = ""
	engine.state["ball"]["pos"] = Vector2(1548, 410)
	engine.state["ball"]["vel"] = Vector2(650, 0)
	for i in range(30):
		engine.step(0.05, {"move": Vector2.ZERO, "aim": Vector2.RIGHT})
	_check(int(engine.state["scores"][0]) >= 1, "goal is detected")
	_check(int(engine.state["stats"]["goals"]) >= 1, "goal stat increments")

func _test_result_bridge(engine: RefCounted) -> void:
	engine.state["status"] = "ended"
	var result: MatchState = engine.build_match_state()
	_check(result.status == "ended", "bridge result ended")
	_check(result.riders.size() == 8, "bridge keeps riders")
	_check(result.scores[0] != result.scores[1], "bridge resolves draw")

func _controlled(engine: RefCounted) -> Dictionary:
	for rider in engine.state["riders"]:
		if str(rider["id"]) == str(engine.state["controlled_id"]):
			return rider
	return {}
