extends SceneTree

const RUN_ENGINE := preload("res://domain/run/run_engine.gd")
const RUN_STATE := preload("res://domain/run/run_state.gd")

var failures: Array[String] = []

func _init() -> void:
	var repo := DataRepository.new()
	_check(repo.load_all(), "data loads")
	var engine = RUN_ENGINE.new()
	var lineup: Array[String] = repo.teams["player"].rider_ids.duplicate()
	_test_map(engine, lineup)
	_test_run_flow(engine, repo, lineup)
	_test_save_roundtrip(engine, lineup)
	if failures.is_empty():
		print("RUN TESTS PASSED: 18 checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _test_map(engine: RefCounted, lineup: Array[String]) -> void:
	var a: RefCounted = engine.new_run(500, lineup)
	var b: RefCounted = engine.new_run(500, lineup)
	var c: RefCounted = engine.new_run(501, lineup)
	_check(_map_signature(a) == _map_signature(b), "same seed creates same map")
	_check(_map_signature(a) != _map_signature(c), "different seed changes map")
	_check(engine.available_nodes(a).size() == 1, "only first node available")
	_check(a.nodes.size() >= 7, "run has branch nodes")
	_check(_has_type(a, RUN_ENGINE.NODE_BOSS), "run has boss")

func _test_run_flow(engine: RefCounted, repo: DataRepository, lineup: Array[String]) -> void:
	var run: RefCounted = engine.new_run(700, lineup)
	var start: Dictionary = engine.start_match(run, "m1")
	_check(bool(start["ok"]), "first match starts")
	var match_engine := MatchEngine.new(repo)
	var match_state := match_engine.create_match(int(start["seed"]), "player", str(start["enemy"]), lineup)
	match_state.scores = [2, 1]
	match_state.status = "ended"
	engine.record_match_result(run, match_state)
	_check(run.pending_reward_pool.size() == 2, "match win creates reward choice")
	engine.apply_reward(run, str(run.pending_reward_pool[0]["id"]))
	_check(run.rewards_taken.size() == 1, "reward applies")
	var available: Array[Dictionary] = engine.available_nodes(run)
	_check(available.size() >= 2, "branch choices unlock")
	var non_match := _first_non_match(available)
	_check(non_match != "", "non-match node is available")
	var applied: Dictionary = engine.apply_camp(run, non_match, "default") if _node_type(run, non_match) == RUN_ENGINE.NODE_CAMP else engine.apply_event(run, non_match, "default")
	_check(bool(applied["ok"]), "camp or event applies")
	_check(run.path.size() >= 2, "path advances")

func _test_save_roundtrip(engine: RefCounted, lineup: Array[String]) -> void:
	var run: RefCounted = engine.new_run(900, lineup)
	run.coins = 17
	run.tutorial_seen = true
	var copy: RefCounted = RUN_STATE.from_dict(run.to_dict())
	_check(copy.seed == run.seed, "save keeps seed")
	_check(copy.coins == 17, "save keeps coins")
	_check(_map_signature(copy) == _map_signature(run), "save keeps map")

func _map_signature(run: RefCounted) -> String:
	var parts: Array[String] = []
	for node in run.nodes:
		parts.append("%s:%s:%s" % [node["id"], node["type"], node["status"]])
	return "|".join(parts)

func _has_type(run: RefCounted, type: String) -> bool:
	for node in run.nodes:
		if str(node["type"]) == type:
			return true
	return false

func _first_non_match(nodes: Array[Dictionary]) -> String:
	for node in nodes:
		if not str(node["type"]) in [RUN_ENGINE.NODE_MATCH, RUN_ENGINE.NODE_ELITE, RUN_ENGINE.NODE_BOSS]:
			return str(node["id"])
	return ""

func _node_type(run: RefCounted, node_id: String) -> String:
	for node in run.nodes:
		if str(node["id"]) == node_id:
			return str(node["type"])
	return ""
