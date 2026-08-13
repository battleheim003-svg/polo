class_name RunState
extends RefCounted

const SCHEMA_VERSION := 1

var run_id: String = ""
var seed: int = 1
var status: String = "ready"
var stage: int = 0
var current_node_id: String = ""
var path: Array[String] = []
var team_id: String = "player"
var lineup: Array[String] = []
var coins: int = 8
var cup_credit: int = 1
var unlocked_tactics: Array[String] = ["hold_line", "safe_pass", "counter", "press", "calm"]
var upgrades: Dictionary = {}
var rewards_taken: Array[String] = []
var events_seen: Array[String] = []
var match_history: Array[Dictionary] = []
var nodes: Array[Dictionary] = []
var pending_reward_pool: Array[Dictionary] = []
var pending_match_node_id: String = ""
var tutorial_seen: bool = false

func to_dict() -> Dictionary:
	return {
		"schema": SCHEMA_VERSION,
		"run_id": run_id,
		"seed": seed,
		"status": status,
		"stage": stage,
		"current_node_id": current_node_id,
		"path": path.duplicate(),
		"team_id": team_id,
		"lineup": lineup.duplicate(),
		"coins": coins,
		"cup_credit": cup_credit,
		"unlocked_tactics": unlocked_tactics.duplicate(),
		"upgrades": upgrades.duplicate(true),
		"rewards_taken": rewards_taken.duplicate(),
		"events_seen": events_seen.duplicate(),
		"match_history": match_history.duplicate(true),
		"nodes": nodes.duplicate(true),
		"pending_reward_pool": pending_reward_pool.duplicate(true),
		"pending_match_node_id": pending_match_node_id,
		"tutorial_seen": tutorial_seen
	}

static func from_dict(data: Dictionary):
	var state = load("res://domain/run/run_state.gd").new()
	if int(data.get("schema", 0)) != SCHEMA_VERSION:
		return state
	state.run_id = str(data.get("run_id", ""))
	state.seed = int(data.get("seed", 1))
	state.status = str(data.get("status", "ready"))
	state.stage = int(data.get("stage", 0))
	state.current_node_id = str(data.get("current_node_id", ""))
	state.path.clear()
	for id in data.get("path", []):
		state.path.append(str(id))
	state.team_id = str(data.get("team_id", "player"))
	state.lineup.clear()
	for id in data.get("lineup", []):
		state.lineup.append(str(id))
	state.coins = int(data.get("coins", 8))
	state.cup_credit = int(data.get("cup_credit", 1))
	state.unlocked_tactics.clear()
	for id in data.get("unlocked_tactics", []):
		state.unlocked_tactics.append(str(id))
	state.upgrades = data.get("upgrades", {}).duplicate(true)
	state.rewards_taken.clear()
	for id in data.get("rewards_taken", []):
		state.rewards_taken.append(str(id))
	state.events_seen.clear()
	for id in data.get("events_seen", []):
		state.events_seen.append(str(id))
	state.match_history.clear()
	for item in data.get("match_history", []):
		state.match_history.append(item)
	state.nodes.clear()
	for item in data.get("nodes", []):
		state.nodes.append(item)
	state.pending_reward_pool.clear()
	for item in data.get("pending_reward_pool", []):
		state.pending_reward_pool.append(item)
	state.pending_match_node_id = str(data.get("pending_match_node_id", ""))
	state.tutorial_seen = bool(data.get("tutorial_seen", false))
	return state
