extends Node

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")
const RUN_ENGINE_SCRIPT := preload("res://domain/run/run_engine.gd")

var repository: DataRepository
var engine: MatchEngine
var run_engine: RefCounted
var current_state: MatchState
var current_run: RefCounted
var current_seed: int = 1403
var current_enemy_id: String = "enemy"
var returning_from_run_match: bool = false
var selected_command: String = "hold_line"
var selected_lineup: Array[String] = []
var break_decision: String = "rest"

func _ready() -> void:
	run_engine = RUN_ENGINE_SCRIPT.new()
	repository = DataRepository.new()
	repository.load_all()
	engine = MatchEngine.new(repository)
	if selected_lineup.is_empty():
		selected_lineup = repository.teams["player"].rider_ids.duplicate()

func start_match(seed_value: int = current_seed) -> MatchState:
	repository = DataRepository.new()
	repository.load_all()
	engine = MatchEngine.new(repository)
	if selected_lineup.is_empty():
		selected_lineup = repository.teams["player"].rider_ids.duplicate()
	current_seed = seed_value
	current_state = engine.create_match(seed_value, "player", current_enemy_id, selected_lineup)
	SaveService.set_value("last_seed", seed_value)
	return current_state

func start_new_run(seed_value: int = current_seed) -> RefCounted:
	if selected_lineup.is_empty():
		selected_lineup = repository.teams["player"].rider_ids.duplicate()
	current_seed = seed_value
	current_run = run_engine.new_run(seed_value, selected_lineup)
	SaveService.set_run(current_run)
	return current_run

func continue_run() -> RefCounted:
	current_run = SaveService.get_run()
	if current_run == null or current_run.status in ["won", "lost"]:
		return start_new_run(current_seed)
	selected_lineup = current_run.lineup.duplicate()
	return current_run

func start_run_match(node_id: String) -> Dictionary:
	if current_run == null:
		continue_run()
	var result: Dictionary = run_engine.start_match(current_run, node_id)
	if bool(result.get("ok", false)):
		current_enemy_id = str(result["enemy"])
		returning_from_run_match = true
		start_match(int(result["seed"]))
	return result

func finish_run_match() -> Dictionary:
	if current_run == null or current_state == null:
		return {"ok": false, "reason": "missing run or match"}
	var result: Dictionary = run_engine.record_match_result(current_run, current_state)
	SaveService.set_run(current_run)
	returning_from_run_match = false
	return result

func apply_run_reward(reward_id: String) -> Dictionary:
	var result: Dictionary = run_engine.apply_reward(current_run, reward_id)
	SaveService.set_run(current_run)
	return result

func apply_run_node(node_id: String, option: String = "default") -> Dictionary:
	if current_run == null:
		continue_run()
	var node := _run_node(node_id)
	var result: Dictionary = {"ok": false, "reason": "missing node"}
	if not node.is_empty():
		match str(node["type"]):
			RUN_ENGINE_SCRIPT.NODE_EVENT:
				result = run_engine.apply_event(current_run, node_id, option)
			RUN_ENGINE_SCRIPT.NODE_CAMP:
				result = run_engine.apply_camp(current_run, node_id, option)
			RUN_ENGINE_SCRIPT.NODE_MARKET:
				result = run_engine.buy_market_item(current_run, node_id, option)
			_:
				result = {"ok": false, "reason": "node requires match"}
	SaveService.set_run(current_run)
	return result

func _run_node(node_id: String) -> Dictionary:
	if current_run == null:
		return {}
	for node in current_run.nodes:
		if str(node["id"]) == node_id:
			return node
	return {}

func set_lineup(rider_ids: Array[String]) -> Dictionary:
	var validation: Dictionary = LINEUP_TOOLS.validate_lineup(repository, rider_ids)
	if bool(validation["ok"]):
		selected_lineup = rider_ids.duplicate()
	return validation

func tick(command: String = selected_command) -> Array[MatchEvent]:
	if current_state == null:
		start_match(current_seed)
	if current_state.substitution_pending:
		return apply_break_decision(break_decision)
	selected_command = command
	return engine.simulate_tick(current_state, [command])

func apply_break_decision(decision: String = "rest") -> Array[MatchEvent]:
	if current_state == null:
		start_match(current_seed)
	break_decision = decision
	return engine.resolve_break_decision(current_state, decision)

func replay_same_seed() -> MatchState:
	return start_match(current_seed)

func new_seed() -> MatchState:
	current_seed = int(Time.get_unix_time_from_system()) % 1000000
	return start_match(current_seed)
