extends SceneTree

const RUN_ENGINE := preload("res://domain/run/run_engine.gd")

const RUNS := 1000
const OUT_PATH := "res://run_report.json"

func _init() -> void:
	var repo := DataRepository.new()
	if not repo.load_all():
		quit(1)
		return
	var run_engine = RUN_ENGINE.new()
	var match_engine := MatchEngine.new(repo)
	var strategies := ["random", "aggressive", "conservative"]
	var summary := {}
	for strategy in strategies:
		summary[strategy] = _simulate_batch(strategy, run_engine, match_engine, repo)
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "\t"))
	print(JSON.stringify(summary))
	quit(0)

func _simulate_batch(strategy: String, run_engine: RefCounted, match_engine: MatchEngine, repo: DataRepository) -> Dictionary:
	var completed := 0
	var boss_reached := 0
	var coins := 0
	var rewards := 0
	var node_counts := {}
	var stamina_before_boss := 0.0
	for i in range(RUNS):
		var run: RefCounted = run_engine.new_run(200000 + i + strategy.length() * 10000, repo.teams["player"].rider_ids)
		var guard := 0
		while run.status == "running" and guard < 20:
			var available: Array[Dictionary] = run_engine.available_nodes(run)
			if available.is_empty():
				run.status = "lost"
				break
			var node := _choose_node(available, strategy, run.seed + guard)
			node_counts[node["type"]] = int(node_counts.get(node["type"], 0)) + 1
			if str(node["type"]) in [RUN_ENGINE.NODE_MATCH, RUN_ENGINE.NODE_ELITE, RUN_ENGINE.NODE_BOSS]:
				if str(node["type"]) == RUN_ENGINE.NODE_BOSS:
					boss_reached += 1
				var start: Dictionary = run_engine.start_match(run, str(node["id"]))
				var match := match_engine.run_to_end(int(start["seed"]), "counter" if strategy == "aggressive" else "calm" if strategy == "conservative" else "hold_line")
				run_engine.record_match_result(run, match)
				if run.pending_reward_pool.size() > 0:
					run_engine.apply_reward(run, _choose_reward(run.pending_reward_pool, strategy))
					rewards += 1
			elif str(node["type"]) == RUN_ENGINE.NODE_MARKET:
				run_engine.buy_market_item(run, str(node["id"]), "market_drill")
			elif str(node["type"]) == RUN_ENGINE.NODE_CAMP:
				run_engine.apply_camp(run, str(node["id"]), "credit" if strategy == "conservative" else "default")
			else:
				run_engine.apply_event(run, str(node["id"]), "credit" if strategy == "conservative" else "default")
			if _next_is_boss(run):
				stamina_before_boss += _lineup_power(run)
			guard += 1
		if run.status == "won":
			completed += 1
		coins += run.coins
	return {
		"runs": RUNS,
		"completion_rate": float(completed) / RUNS,
		"boss_reach_rate": float(boss_reached) / RUNS,
		"average_coins": float(coins) / RUNS,
		"average_rewards": float(rewards) / RUNS,
		"node_counts": node_counts,
		"average_stamina_before_boss": stamina_before_boss / max(1, boss_reached),
		"average_logical_duration_minutes": 24.0
	}

func _choose_node(nodes: Array[Dictionary], strategy: String, salt: int) -> Dictionary:
	if strategy == "aggressive":
		for node in nodes:
			if str(node["type"]) in [RUN_ENGINE.NODE_ELITE, RUN_ENGINE.NODE_MATCH, RUN_ENGINE.NODE_BOSS]:
				return node
	if strategy == "conservative":
		for node in nodes:
			if str(node["type"]) in [RUN_ENGINE.NODE_CAMP, RUN_ENGINE.NODE_EVENT]:
				return node
	return nodes[int(DeterministicRng.value(salt, 9) * nodes.size()) % nodes.size()]

func _choose_reward(rewards: Array[Dictionary], strategy: String) -> String:
	for reward in rewards:
		if strategy == "aggressive" and str(reward["type"]) == "strike":
			return str(reward["id"])
		if strategy == "conservative" and str(reward["type"]) in ["stamina", "focus"]:
			return str(reward["id"])
	return str(rewards[0]["id"])

func _next_is_boss(run: RefCounted) -> bool:
	for node in run.nodes:
		if str(node["status"]) == "available" and str(node["type"]) == RUN_ENGINE.NODE_BOSS:
			return true
	return false

func _lineup_power(run: RefCounted) -> float:
	var total := 0
	for value in run.upgrades.values():
		total += int(value)
	return float(total)
