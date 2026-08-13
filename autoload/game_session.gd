extends Node

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")

var repository: DataRepository
var engine: MatchEngine
var current_state: MatchState
var current_seed: int = 1403
var selected_command: String = "hold_line"
var selected_lineup: Array[String] = []
var break_decision: String = "rest"

func _ready() -> void:
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
	current_state = engine.create_match(seed_value, "player", "enemy", selected_lineup)
	SaveService.set_value("last_seed", seed_value)
	return current_state

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
