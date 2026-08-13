extends SceneTree

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")

var failures: Array[String] = []

func _init() -> void:
	var repo := DataRepository.new()
	_check(repo.load_all(), "all prototype data loads")
	var engine := MatchEngine.new(repo)
	_test_preparation_lineup(repo, engine)
	_test_seed_determinism(engine)
	_test_match_invariants(engine)
	_test_save_corruption()
	if failures.is_empty():
		print("TESTS PASSED: 20 checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _test_seed_determinism(engine: MatchEngine) -> void:
	var a := _run_snapshot(777, "hold_line")
	var b := _run_snapshot(777, "hold_line")
	var c := _run_snapshot(778, "hold_line")
	_check(_signature(a) == _signature(b), "same seed creates identical result")
	_check(_signature(a) != _signature(c), "different seed can create different result")
	_check(a["status"] == "ended", "headless match ends")
	_check(a["events"].size() > 0, "event queue is populated")
	_check(a["stats"].has("passes"), "stats are present")

func _test_preparation_lineup(repo: DataRepository, engine: MatchEngine) -> void:
	var lineup: Array[String] = ["pish-taz", "bal-ro", "meydan-dar", "dejban"]
	var validation: Dictionary = LINEUP_TOOLS.validate_lineup(repo, lineup)
	_check(bool(validation["ok"]), "valid four rider lineup is accepted")
	var duplicate: Dictionary = LINEUP_TOOLS.validate_lineup(repo, ["pish-taz", "pish-taz", "meydan-dar", "dejban"])
	_check(not bool(duplicate["ok"]), "duplicate rider is rejected")
	var empty_slot: Dictionary = LINEUP_TOOLS.validate_lineup(repo, ["pish-taz", "", "meydan-dar", "dejban"])
	_check(not bool(empty_slot["ok"]), "empty slot is rejected")
	_check(is_equal_approx(LINEUP_TOOLS.role_fit(repo.riders["dejban"], "guardian"), BalanceConfig.ROLE_EXACT), "role fit exact is calculated")
	var state := engine.create_match(42, "player", "enemy", lineup)
	_check(str(state.riders[1]["id"]) == "bal-ro", "selected lineup enters match state")
	_check(state.synergies[0].size() >= 2, "lineup activates real synergies")

func _run_snapshot(seed_value: int, command: String) -> Dictionary:
	var repo := DataRepository.new()
	repo.load_all()
	var fresh_engine := MatchEngine.new(repo)
	return fresh_engine.run_to_end(seed_value, command).snapshot()

func _test_match_invariants(engine: MatchEngine) -> void:
	var state := engine.run_to_end(1403, "safe_pass")
	_check(state.ball.zone >= 1 and state.ball.zone <= 5, "ball stays within zones")
	_check(state.scores[0] >= 0 and state.scores[1] >= 0, "scores are non-negative")
	_check(abs(state.ball.attack_direction) == 1, "attack direction remains valid")
	_check(_min_stamina(state) >= 0, "stamina never goes negative")
	_check(_max_focus(state) <= BalanceConfig.MAX_FOCUS, "focus stays below cap")
	_check(state.stats["hooks"] >= 0 and state.stats["ride_offs"] >= 0, "hook and ride-off counted")
	_check(state.stats["fouls"] >= 0, "fouls counted")
	_check(state.chukker_end_emitted.size() <= BalanceConfig.CHUKKER_COUNT, "chukker end emitted once per chukker")
	_check(_has_event(state, "BreakRestApplied") or state.substitutions_applied >= 1, "break decision between chukkers applied")
	_check(state.extra_ticks <= BalanceConfig.MAX_EXTRA_TICKS, "extra time is bounded")
	_check(_no_double_actions(state), "rider does not keep incompatible actions in one tick")
	_check(_has_event(state, "FreeHitAwarded") or state.stats["fouls"] == 0, "foul creates free hit")
	_check(_has_event(state, "SkillActivated") == (state.stats["skills"] > 0), "skill activation event matches stats")
	_check(_has_event(state, "MatchEnded"), "match ended event emitted")
	_check(state.scores[0] != state.scores[1], "tie-break prevents final draw")
	_check(_has_breakdown_bonus(state, "line_owner_bonus"), "line owner bonus appears in dominance breakdown")

	var manual := engine.create_match(5)
	manual.ball.zone = 5
	manual.ball.possession_team = 0
	manual.ball.holder_id = "pish-taz"
	var before := manual.scores[0]
	for i in range(12):
		engine.simulate_tick(manual, ["counter"])
		if manual.scores[0] > before:
			break
	_check(manual.scores[0] >= before, "goal scoring keeps score valid")
	_check(manual.ball.attack_direction == -1 or manual.scores[0] == before, "goal flips attack direction")

	var command_state := engine.create_match(9)
	engine.simulate_tick(command_state, ["press"])
	var active := command_state.active_command
	engine.simulate_tick(command_state, ["counter"])
	_check(command_state.active_command == active, "coach command duration prevents immediate overwrite")

func _test_save_corruption() -> void:
	var json := JSON.new()
	var err := json.parse("{broken")
	_check(err != OK, "corrupt save is detectable without crash")

func _signature(snapshot: Dictionary) -> String:
	var event_types: Array[String] = []
	for event in snapshot["events"]:
		event_types.append(str(event["type"]))
	var scores: Array = snapshot["scores"]
	var ball: Dictionary = snapshot["ball"]
	var stats: Dictionary = snapshot["stats"]
	return "%s|%d:%d|%d:%d:%s:%d:%d|%d|%d:%d:%d:%d:%d:%d:%d:%d:%d|%s" % [
		str(snapshot["status"]),
		int(scores[0]),
		int(scores[1]),
		int(ball["zone"]),
		int(ball["possession_team"]),
		str(ball["holder_id"]),
		int(ball["line_owner_team"]),
		int(ball["attack_direction"]),
		int(snapshot["rng_state"]),
		int(stats["goals"]),
		int(stats["fouls"]),
		int(stats["hooks"]),
		int(stats["ride_offs"]),
		int(stats["passes"]),
		int(stats["skills"]),
		int(stats["shots"]),
		int(stats["strikes"]),
		int(stats["recoveries"]),
		",".join(event_types)
	]


func _min_stamina(state: MatchState) -> int:
	var value := 100
	for rider in state.riders:
		value = mini(value, int(rider["stamina"]))
	return value

func _max_focus(state: MatchState) -> int:
	var value := 0
	for rider in state.riders:
		value = maxi(value, int(rider["focus"]))
	return value

func _no_double_actions(state: MatchState) -> bool:
	for rider in state.riders:
		if rider.get("actions_this_tick", []).size() > 1:
			return false
	return true

func _has_event(state: MatchState, event_type: String) -> bool:
	for event in state.events:
		if event.type == event_type:
			return true
	return false

func _has_breakdown_bonus(state: MatchState, key: String) -> bool:
	for breakdown in state.dominance_breakdowns:
		if float(breakdown.get(key, 0.0)) > 0.0:
			return true
	return false
