class_name MatchState
extends RefCounted

var chukker: int = 1
var time_remaining: int = BalanceConfig.CHUKKER_SECONDS
var scores: Array[int] = [0, 0]
var riders: Array[Dictionary] = []
var horses: Dictionary = {}
var ball: BallState = BallState.new()
var pressure: Array[float] = [0.0, 0.0]
var active_command: String = "hold_line"
var command_ticks_remaining: int = 0
var command_uses: Dictionary = {}
var seed: int = 1
var rng_state: int = 1
var status: String = "ready"
var events: Array[MatchEvent] = []
var stats: Dictionary = {
	"goals": 0, "fouls": 0, "hooks": 0, "ride_offs": 0, "passes": 0,
	"skills": 0, "shots": 0, "strikes": 0, "recoveries": 0
}
var extra_ticks: int = 0
var chukker_end_emitted: Dictionary = {}
var skill_tick_guard: Dictionary = {}
var substitutions_applied: int = 0
var substitution_pending: bool = false
var pending_substitution_team: int = -1
var tick_index: int = 0
var synergies: Dictionary = {0: [], 1: []}
var dominance_breakdowns: Array[Dictionary] = []

func _init() -> void:
	chukker = 1
	time_remaining = BalanceConfig.CHUKKER_SECONDS
	scores = [0, 0]
	riders = []
	horses = {}
	ball = BallState.new()
	pressure = [0.0, 0.0]
	active_command = "hold_line"
	command_ticks_remaining = 0
	command_uses = {}
	seed = 1
	rng_state = 1
	status = "ready"
	events = []
	stats = {
		"goals": 0, "fouls": 0, "hooks": 0, "ride_offs": 0, "passes": 0,
		"skills": 0, "shots": 0, "strikes": 0, "recoveries": 0
	}
	extra_ticks = 0
	chukker_end_emitted = {}
	skill_tick_guard = {}
	substitutions_applied = 0
	substitution_pending = false
	pending_substitution_team = -1
	tick_index = 0
	synergies = {0: [], 1: []}
	dominance_breakdowns = []

func snapshot() -> Dictionary:
	var event_list: Array = []
	for e in events:
		event_list.append(e.to_dict())
	return {
		"chukker": chukker,
		"time_remaining": time_remaining,
		"scores": scores.duplicate(),
		"riders": riders.duplicate(true),
		"horses": horses.duplicate(true),
		"ball": {
			"zone": ball.zone,
			"possession_team": ball.possession_team,
			"holder_id": ball.holder_id,
			"line_owner_team": ball.line_owner_team,
			"attack_direction": ball.attack_direction,
			"controlled": ball.controlled
		},
		"pressure": pressure.duplicate(),
		"active_command": active_command,
		"command_ticks_remaining": command_ticks_remaining,
		"command_uses": command_uses.duplicate(true),
		"seed": seed,
		"rng_state": rng_state,
		"status": status,
		"events": event_list,
		"stats": stats.duplicate(true),
		"extra_ticks": extra_ticks,
		"substitutions_applied": substitutions_applied,
		"substitution_pending": substitution_pending,
		"synergies": synergies.duplicate(true),
		"dominance_breakdowns": dominance_breakdowns.duplicate(true),
		"tick_index": tick_index
	}
