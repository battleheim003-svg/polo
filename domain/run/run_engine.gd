class_name RunEngine
extends RefCounted

const NODE_MATCH := "MATCH"
const NODE_EVENT := "EVENT"
const NODE_CAMP := "CAMP"
const NODE_MARKET := "MARKET"
const NODE_ELITE := "ELITE"
const NODE_BOSS := "BOSS"

const REWARDS := [
	{"id":"sharp_mallets","name":"Sharp Mallets","type":"strike","amount":3},
	{"id":"steady_reins","name":"Steady Reins","type":"control","amount":3},
	{"id":"deep_breath","name":"Deep Breath","type":"focus","amount":5},
	{"id":"fresh_horses","name":"Fresh Horses","type":"stamina","amount":8},
	{"id":"line_drill","name":"Line Drill","type":"line","amount":1}
]

const EVENTS := [
	{"id":"village_oath","name":"Village Oath","text":"Gain cup credit or coins.", "credit":1, "coins":4},
	{"id":"dust_storm","name":"Dust Storm","text":"Spend credit to avoid stamina loss.", "credit":-1, "stamina":-5},
	{"id":"old_coach","name":"Old Coach","text":"Learn a focused drill.", "focus":4, "coins":-3}
]

func new_run(seed_value: int, lineup: Array[String]):
	var state = load("res://domain/run/run_state.gd").new()
	state.seed = seed_value
	state.run_id = "run-%d" % seed_value
	state.status = "running"
	state.stage = 0
	state.lineup = lineup.duplicate()
	state.nodes = _generate_map(seed_value)
	state.current_node_id = _first_available(state)
	return state

func available_nodes(state: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in state.nodes:
		if str(node["status"]) == "available":
			result.append(node)
	return result

func choose_node(state: RefCounted, node_id: String) -> Dictionary:
	var node := _node(state, node_id)
	if node.is_empty():
		return {"ok": false, "reason": "missing node"}
	if str(node["status"]) != "available":
		return {"ok": false, "reason": "node is not available"}
	node["status"] = "current"
	state.current_node_id = node_id
	return {"ok": true, "node": node}

func start_match(state: RefCounted, node_id: String) -> Dictionary:
	var chosen := choose_node(state, node_id)
	if not bool(chosen["ok"]):
		return chosen
	var node: Dictionary = chosen["node"]
	if not str(node["type"]) in [NODE_MATCH, NODE_ELITE, NODE_BOSS]:
		return {"ok": false, "reason": "node is not a match"}
	state.pending_match_node_id = node_id
	return {"ok": true, "enemy": str(node["enemy_id"]), "seed": state.seed + int(node["row"]) * 101}

func record_match_result(state: RefCounted, match_state: MatchState) -> Dictionary:
	var node := _node(state, state.pending_match_node_id)
	var won := match_state.scores[0] > match_state.scores[1]
	state.match_history.append({
		"node": state.pending_match_node_id,
		"enemy": node.get("enemy_id", ""),
		"won": won,
		"score": match_state.scores.duplicate(),
		"seed": match_state.seed
	})
	if won:
		state.coins += 6 if str(node.get("type", "")) != NODE_BOSS else 12
		state.pending_reward_pool.assign(reward_pool(state, int(node.get("row", 0))))
		_complete_current(state)
		if str(node.get("type", "")) == NODE_BOSS:
			state.status = "won"
	else:
		state.cup_credit -= 1
		if state.cup_credit < 0:
			state.status = "lost"
		else:
			state.pending_reward_pool.assign(reward_pool(state, int(node.get("row", 0))))
			_complete_current(state)
	state.pending_match_node_id = ""
	return {"ok": true, "won": won, "status": state.status}

func apply_reward(state: RefCounted, reward_id: String) -> Dictionary:
	for reward in state.pending_reward_pool:
		if str(reward["id"]) == reward_id:
			_apply_reward(state, reward)
			state.rewards_taken.append(reward_id)
			state.pending_reward_pool.clear()
			return {"ok": true}
	return {"ok": false, "reason": "missing reward"}

func apply_event(state: RefCounted, node_id: String, option: String) -> Dictionary:
	var chosen := choose_node(state, node_id)
	if not bool(chosen["ok"]):
		return chosen
	var node: Dictionary = chosen["node"]
	var event: Dictionary = EVENTS[int(node["row"]) % EVENTS.size()]
	state.events_seen.append(event["id"])
	if option == "credit":
		state.cup_credit += int(event.get("credit", 0))
	else:
		state.coins = max(0, state.coins + int(event.get("coins", 0)))
		if event.has("focus"):
			state.upgrades["focus"] = int(state.upgrades.get("focus", 0)) + int(event["focus"])
	_complete_current(state)
	return {"ok": true, "event": event}

func apply_camp(state: RefCounted, node_id: String, option: String) -> Dictionary:
	var chosen := choose_node(state, node_id)
	if not bool(chosen["ok"]):
		return chosen
	if option == "credit" and state.cup_credit > 0:
		state.cup_credit -= 1
		state.upgrades["stamina"] = int(state.upgrades.get("stamina", 0)) + 12
	else:
		state.upgrades["focus"] = int(state.upgrades.get("focus", 0)) + 5
	_complete_current(state)
	return {"ok": true}

func buy_market_item(state: RefCounted, node_id: String, item_id: String) -> Dictionary:
	var chosen := choose_node(state, node_id)
	if not bool(chosen["ok"]):
		return chosen
	var cost := 7
	if state.coins < cost:
		return {"ok": false, "reason": "not enough coins"}
	state.coins -= cost
	_apply_reward(state, {"id": item_id, "type": "control", "amount": 3})
	_complete_current(state)
	return {"ok": true}

func reward_pool(state: RefCounted, salt: int) -> Array[Dictionary]:
	var a: Dictionary = REWARDS[int(DeterministicRng.value(state.seed, salt * 20 + 1) * REWARDS.size()) % REWARDS.size()]
	var b: Dictionary = REWARDS[int(DeterministicRng.value(state.seed, salt * 20 + 2) * REWARDS.size()) % REWARDS.size()]
	if a["id"] == b["id"]:
		b = REWARDS[(REWARDS.find(b) + 1) % REWARDS.size()]
	return [a.duplicate(), b.duplicate()]

func _generate_map(seed_value: int) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	nodes.append(_make_node("m1", NODE_MATCH, 1, "east_wind", [], ["e1", "c1"]))
	var row2_event := "e1" if seed_value % 2 == 0 else "e2"
	nodes.append(_make_node(row2_event, NODE_EVENT, 2, "", ["m1"], ["m2", "elite1"]))
	nodes.append(_make_node("c1", NODE_CAMP, 2, "", ["m1"], ["m2", "elite1"]))
	nodes.append(_make_node("m2", NODE_MATCH, 3, "stoneguard", [row2_event, "c1"], ["market1", "camp2"]))
	nodes.append(_make_node("elite1", NODE_ELITE, 3, "stoneguard", [row2_event, "c1"], ["market1", "camp2"]))
	nodes.append(_make_node("market1", NODE_MARKET, 4, "", ["m2", "elite1"], ["boss"]))
	nodes.append(_make_node("camp2", NODE_CAMP, 4, "", ["m2", "elite1"], ["boss"]))
	nodes.append(_make_node("boss", NODE_BOSS, 5, "cup_guardians", ["market1", "camp2"], []))
	for node in nodes:
		node["status"] = "locked"
	nodes[0]["status"] = "available"
	return nodes

func _make_node(id: String, type: String, row: int, enemy_id: String, incoming: Array[String], outgoing: Array[String]) -> Dictionary:
	return {"id": id, "type": type, "row": row, "incoming": incoming.duplicate(), "outgoing": outgoing.duplicate(), "status": "locked", "enemy_id": enemy_id, "preview": _preview(type)}

func _preview(type: String) -> String:
	match type:
		NODE_MATCH: return "Standard cup match."
		NODE_ELITE: return "Harder rival, richer reward."
		NODE_EVENT: return "A short run event."
		NODE_CAMP: return "Recover or train."
		NODE_MARKET: return "Spend coins on a drill."
		NODE_BOSS: return "Final cup guardians."
		_: return ""

func _complete_current(state: RefCounted) -> void:
	var node := _node(state, state.current_node_id)
	if node.is_empty():
		return
	node["status"] = "completed"
	state.path.append(str(node["id"]))
	state.stage = maxi(state.stage, int(node["row"]))
	for outgoing in node["outgoing"]:
		var target := _node(state, str(outgoing))
		if not target.is_empty() and str(target["status"]) == "locked":
			target["status"] = "available"
	state.current_node_id = _first_available(state)

func _apply_reward(state: RefCounted, reward: Dictionary) -> void:
	var key := str(reward.get("type", ""))
	state.upgrades[key] = int(state.upgrades.get(key, 0)) + int(reward.get("amount", 0))

func _first_available(state: RefCounted) -> String:
	for node in state.nodes:
		if str(node["status"]) == "available":
			return str(node["id"])
	return ""

func _node(state: RefCounted, node_id: String) -> Dictionary:
	for node in state.nodes:
		if str(node["id"]) == node_id:
			return node
	return {}
