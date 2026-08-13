extends SceneTree

func _init() -> void:
	var repo := DataRepository.new()
	if not repo.load_all():
		push_error("Repository failed to load in smoke test.")
		quit(1)
		return
	var engine := MatchEngine.new(repo)
	var state := engine.create_match(2026)
	for i in range(8):
		engine.simulate_tick(state, ["hold_line"])
	if state.events.size() < 4:
		push_error("Smoke test did not produce enough events.")
		quit(1)
		return
	if state.ball.zone < 1 or state.ball.zone > 5:
		push_error("Smoke test ball zone out of bounds.")
		quit(1)
		return
	print("SMOKE PASSED: scene data and match loop are available")
	quit(0)
