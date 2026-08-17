class_name InteractiveMatchEngine
extends RefCounted

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")

const FIELD_SIZE := Vector2(1600, 820)
const MIN_BOUNDS := Vector2(80, 90)
const MAX_BOUNDS := Vector2(1520, 730)
const LEFT_GOAL_X := 44.0
const RIGHT_GOAL_X := 1556.0
const GOAL_Y_MIN := 318.0
const GOAL_Y_MAX := 502.0
const BALL_RADIUS := 12.0
const RIDER_RADIUS := 28.0
const MATCH_SECONDS := 150
const CHUKKERS := 2

var repo: DataRepository
var state: Dictionary = {}
var events: Array[Dictionary] = []

func _init(repository: DataRepository = null) -> void:
	repo = repository

func create_match(seed_value: int, player_team_id: String, enemy_team_id: String, player_lineup: Array[String]) -> Dictionary:
	events.clear()
	state = {
		"seed": seed_value,
		"team_ids": [player_team_id, enemy_team_id],
		"status": "playing",
		"chukker": 1,
		"time_remaining": MATCH_SECONDS,
		"scores": [0, 0],
		"stats": {"goals": 0, "fouls": 0, "hooks": 0, "ride_offs": 0, "passes": 0, "skills": 0, "shots": 0, "strikes": 0, "recoveries": 0},
		"riders": [],
		"ball": {"pos": FIELD_SIZE * 0.5, "vel": Vector2.ZERO, "holder": "", "team": -1, "free_hit_team": -1},
		"controlled_id": "",
		"last_action": "",
		"phase": "normal"
	}
	_spawn_team(0, player_team_id, player_lineup)
	var enemy_lineup: Array[String] = repo.teams[enemy_team_id].rider_ids.duplicate()
	_spawn_team(1, enemy_team_id, enemy_lineup)
	state["controlled_id"] = str(state["riders"][0]["id"])
	_recover_ball(str(state["controlled_id"]), 0)
	return state

func step(delta: float, input: Dictionary = {}) -> Array[Dictionary]:
	events.clear()
	if state.is_empty() or str(state.get("status", "")) != "playing":
		return events
	var dt := clampf(delta, 0.0, 0.05)
	_update_clock(dt)
	_update_controlled(dt, input)
	_update_ai(dt)
	_update_ball(dt)
	_resolve_contacts(input)
	_check_goal()
	return events.duplicate(true)

func build_match_state() -> MatchState:
	var result := MatchState.new()
	result.seed = int(state.get("seed", 1))
	result.team_ids = [str(state["team_ids"][0]), str(state["team_ids"][1])]
	result.status = "ended"
	result.chukker = int(state.get("chukker", 1))
	result.time_remaining = int(state.get("time_remaining", 0))
	result.scores = [int(state["scores"][0]), int(state["scores"][1])]
	result.stats = state["stats"].duplicate(true)
	result.riders = []
	for rider in state["riders"]:
		result.riders.append({
			"id": str(rider["rider_id"]),
			"team": int(rider["team"]),
			"slot": int(rider["slot"]),
			"role": str(rider["role"]),
			"stamina": int(rider["stamina"]),
			"focus": int(rider["focus"])
		})
	if result.scores[0] == result.scores[1]:
		var winner := int(state["seed"]) % 2
		result.scores[winner] += 1
	return result

func switch_to_nearest_player() -> void:
	var ball_pos: Vector2 = state["ball"]["pos"]
	var best_id := str(state["controlled_id"])
	var best_dist := INF
	for rider in state["riders"]:
		if int(rider["team"]) != 0:
			continue
		var d := ball_pos.distance_squared_to(rider["pos"])
		if d < best_dist:
			best_dist = d
			best_id = str(rider["id"])
	state["controlled_id"] = best_id
	_emit("ControlChanged", "Control changed.", {"id": best_id})

func _spawn_team(team: int, team_id: String, lineup: Array[String]) -> void:
	var xs := [280.0, 430.0, 610.0, 790.0] if team == 0 else [1320.0, 1170.0, 990.0, 810.0]
	var ys := [230.0, 390.0, 560.0, 690.0]
	for i in range(4):
		var rider_id := lineup[i]
		var rider: RiderDefinition = repo.riders[rider_id]
		var horse: HorseDefinition = repo.horses[rider.horse_id]
		state["riders"].append({
			"id": "%d-%s" % [team, rider_id],
			"rider_id": rider_id,
			"team": team,
			"slot": i,
			"role": LINEUP_TOOLS.role_for_slot(i),
			"pos": Vector2(xs[i], ys[i]),
			"vel": Vector2.ZERO,
			"facing": Vector2.RIGHT if team == 0 else Vector2.LEFT,
			"stamina": horse.stamina,
			"focus": rider.focus,
			"speed": 190.0 + horse.stamina * 1.1,
			"turn": 7.0 + horse.coordination * 0.04,
			"state": "support",
			"cooldown": 0.0
		})

func _update_clock(delta: float) -> void:
	state["time_remaining"] = maxf(0.0, float(state["time_remaining"]) - delta)
	if float(state["time_remaining"]) > 0.0:
		return
	if int(state["chukker"]) < CHUKKERS:
		state["chukker"] = int(state["chukker"]) + 1
		state["time_remaining"] = MATCH_SECONDS
		_reset_positions()
		_emit("ChukkerBreak", "Chukker break.", {"chukker": state["chukker"]})
	else:
		state["status"] = "ended"
		_emit("MatchEnded", "Match ended.", {"scores": state["scores"].duplicate()})

func _update_controlled(delta: float, input: Dictionary) -> void:
	var rider := _rider(str(state["controlled_id"]))
	if rider.is_empty():
		return
	var move: Vector2 = input.get("move", Vector2.ZERO)
	if move.length() > 1.0:
		move = move.normalized()
	var target_vel := move * float(rider["speed"])
	rider["vel"] = Vector2(rider["vel"]).move_toward(target_vel, 760.0 * delta)
	if move.length() > 0.1:
		rider["facing"] = Vector2(rider["facing"]).slerp(move.normalized(), clampf(float(rider["turn"]) * delta, 0.0, 1.0))
		rider["stamina"] = maxf(0.0, float(rider["stamina"]) - delta * 1.4)
	_move_rider(rider, delta)
	if bool(input.get("switch", false)):
		switch_to_nearest_player()
	if bool(input.get("pass", false)):
		_pass(rider)
	if bool(input.get("hook", false)):
		_hook(rider)
	if bool(input.get("ride_off", false)):
		_ride_off(rider)
	if bool(input.get("strike", false)):
		var aim: Vector2 = input.get("aim", rider["facing"])
		_strike(rider, aim)

func _update_ai(delta: float) -> void:
	var ball_pos: Vector2 = state["ball"]["pos"]
	for rider in state["riders"]:
		if str(rider["id"]) == str(state["controlled_id"]):
			continue
		var team := int(rider["team"])
		var target := _role_target(team, int(rider["slot"]), ball_pos)
		var holder := str(state["ball"]["holder"])
		if holder != "" and _rider(holder).get("team", -1) != team:
			target = ball_pos + Vector2(-80 if team == 0 else 80, (int(rider["slot"]) - 1.5) * 46)
		elif holder == "" and ball_pos.distance_to(rider["pos"]) < 220:
			target = ball_pos
		var desired := (target - Vector2(rider["pos"]))
		var move := desired.normalized() if desired.length() > 4.0 else Vector2.ZERO
		rider["vel"] = Vector2(rider["vel"]).move_toward(move * float(rider["speed"]) * 0.72, 520.0 * delta)
		if move.length() > 0.1:
			rider["facing"] = Vector2(rider["facing"]).slerp(move.normalized(), clampf(float(rider["turn"]) * delta, 0.0, 1.0))
		_move_rider(rider, delta)
		if holder == "" and Vector2(rider["pos"]).distance_to(ball_pos) < 34.0:
			_recover_ball(str(rider["id"]), team)

func _update_ball(delta: float) -> void:
	var holder_id := str(state["ball"]["holder"])
	if holder_id != "":
		var holder := _rider(holder_id)
		if not holder.is_empty():
			state["ball"]["pos"] = Vector2(holder["pos"]) + Vector2(holder["facing"]) * 38.0
			state["ball"]["team"] = int(holder["team"])
			return
	var pos: Vector2 = state["ball"]["pos"]
	var vel: Vector2 = state["ball"]["vel"]
	pos += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 96.0 * delta)
	state["ball"]["pos"] = pos
	_check_goal()
	if str(state.get("status", "")) != "playing" or Vector2(state["ball"]["pos"]).is_equal_approx(FIELD_SIZE * 0.5):
		return
	pos.x = clampf(pos.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
	pos.y = clampf(pos.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
	state["ball"]["pos"] = pos
	state["ball"]["vel"] = vel
	for rider in state["riders"]:
		if Vector2(rider["pos"]).distance_to(pos) < 32.0 and vel.length() < 260.0:
			_recover_ball(str(rider["id"]), int(rider["team"]))
			break

func _resolve_contacts(input: Dictionary) -> void:
	var controlled := _rider(str(state["controlled_id"]))
	if controlled.is_empty():
		return
	for rider in state["riders"]:
		if int(rider["team"]) == int(controlled["team"]):
			continue
		var dist := Vector2(rider["pos"]).distance_to(controlled["pos"])
		if dist < RIDER_RADIUS * 1.55 and bool(input.get("ride_off", false)):
			_ride_off(controlled)

func _strike(rider: Dictionary, aim: Vector2) -> void:
	if aim.length() < 0.1:
		aim = Vector2(rider["facing"])
	var close := Vector2(rider["pos"]).distance_to(state["ball"]["pos"]) < 76.0
	if str(state["ball"]["holder"]) != str(rider["id"]) and not close:
		return
	state["ball"]["holder"] = ""
	state["ball"]["vel"] = aim.normalized() * 650.0
	state["ball"]["pos"] = Vector2(rider["pos"]) + aim.normalized() * 46.0
	state["stats"]["strikes"] = int(state["stats"]["strikes"]) + 1
	if _is_attacking_goal(int(rider["team"]), Vector2(state["ball"]["pos"])):
		state["stats"]["shots"] = int(state["stats"]["shots"]) + 1
	_emit("Strike", "Strike!", {"team": rider["team"], "pos": state["ball"]["pos"]})

func _pass(rider: Dictionary) -> void:
	var teammate := _best_pass_target(int(rider["team"]), str(rider["id"]))
	if teammate.is_empty():
		return
	var dir := (Vector2(teammate["pos"]) - Vector2(rider["pos"])).normalized()
	state["ball"]["holder"] = ""
	state["ball"]["pos"] = Vector2(rider["pos"]) + dir * 44.0
	state["ball"]["vel"] = dir * 520.0
	state["stats"]["passes"] = int(state["stats"]["passes"]) + 1
	_emit("Pass", "Pass released.", {"target": teammate["id"]})

func _hook(rider: Dictionary) -> void:
	var opponent := _nearest_opponent(int(rider["team"]), Vector2(rider["pos"]), 82.0)
	if opponent.is_empty():
		return
	var legal := Vector2(rider["facing"]).dot((Vector2(opponent["pos"]) - Vector2(rider["pos"])).normalized()) > 0.15
	if legal:
		state["ball"]["holder"] = ""
		state["ball"]["vel"] = Vector2.ZERO
		state["stats"]["hooks"] = int(state["stats"]["hooks"]) + 1
		_emit("Hook", "Hook!", {"team": rider["team"]})
	else:
		_award_free_hit(1 - int(rider["team"]), "bad hook")

func _ride_off(rider: Dictionary) -> void:
	var opponent := _nearest_opponent(int(rider["team"]), Vector2(rider["pos"]), 70.0)
	if opponent.is_empty():
		return
	var strength := float(repo.riders[str(rider["rider_id"])].ride) + float(rider["stamina"]) * 0.12
	var other := float(repo.riders[str(opponent["rider_id"])].ride) + float(opponent["stamina"]) * 0.12
	if strength >= other * 0.86:
		opponent["vel"] = Vector2(opponent["vel"]) + (Vector2(opponent["pos"]) - Vector2(rider["pos"])).normalized() * 120.0
		state["stats"]["ride_offs"] = int(state["stats"]["ride_offs"]) + 1
		_emit("RideOff", "Ride-off.", {"team": rider["team"]})
	else:
		_award_free_hit(1 - int(rider["team"]), "dangerous ride-off")

func _check_goal() -> void:
	var pos: Vector2 = state["ball"]["pos"]
	if pos.y < GOAL_Y_MIN or pos.y > GOAL_Y_MAX:
		return
	if pos.x <= LEFT_GOAL_X:
		_goal(1)
	elif pos.x >= RIGHT_GOAL_X:
		_goal(0)

func _goal(team: int) -> void:
	state["scores"][team] = int(state["scores"][team]) + 1
	state["stats"]["goals"] = int(state["stats"]["goals"]) + 1
	_emit("Goal", "Goal!", {"team": team, "scores": state["scores"].duplicate()})
	_reset_positions()

func _reset_positions() -> void:
	for rider in state["riders"]:
		var team := int(rider["team"])
		var slot := int(rider["slot"])
		rider["pos"] = Vector2([280.0, 430.0, 610.0, 790.0][slot], [230.0, 390.0, 560.0, 690.0][slot]) if team == 0 else Vector2([1320.0, 1170.0, 990.0, 810.0][slot], [230.0, 390.0, 560.0, 690.0][slot])
		rider["vel"] = Vector2.ZERO
	state["ball"]["pos"] = FIELD_SIZE * 0.5
	state["ball"]["vel"] = Vector2.ZERO
	state["ball"]["holder"] = str(state["controlled_id"])

func _recover_ball(rider_id: String, team: int) -> void:
	state["ball"]["holder"] = rider_id
	state["ball"]["team"] = team
	state["ball"]["vel"] = Vector2.ZERO
	state["stats"]["recoveries"] = int(state["stats"]["recoveries"]) + 1
	_emit("Recovery", "Ball recovered.", {"team": team, "holder": rider_id})

func _award_free_hit(team: int, reason: String) -> void:
	state["stats"]["fouls"] = int(state["stats"]["fouls"]) + 1
	state["ball"]["free_hit_team"] = team
	state["ball"]["holder"] = _nearest_team_rider(team, Vector2(state["ball"]["pos"]))
	_emit("FreeHit", "Free hit.", {"team": team, "reason": reason})

func _move_rider(rider: Dictionary, delta: float) -> void:
	var pos: Vector2 = Vector2(rider["pos"]) + Vector2(rider["vel"]) * delta
	pos.x = clampf(pos.x, MIN_BOUNDS.x, MAX_BOUNDS.x)
	pos.y = clampf(pos.y, MIN_BOUNDS.y, MAX_BOUNDS.y)
	rider["pos"] = pos

func _role_target(team: int, slot: int, ball_pos: Vector2) -> Vector2:
	var attack_dir := 1 if team == 0 else -1
	var lanes: Array[float] = [210.0, 360.0, 520.0, 665.0]
	var lane_y: float = lanes[slot]
	var x := clampf(ball_pos.x - attack_dir * (220.0 - slot * 45.0), MIN_BOUNDS.x, MAX_BOUNDS.x)
	if slot == 3:
		x = 260.0 if team == 0 else 1340.0
	return Vector2(x, lane_y)

func _rider(id: String) -> Dictionary:
	for rider in state.get("riders", []):
		if str(rider["id"]) == id:
			return rider
	return {}

func _nearest_opponent(team: int, pos: Vector2, radius: float) -> Dictionary:
	var best := {}
	var best_dist := radius * radius
	for rider in state["riders"]:
		if int(rider["team"]) == team:
			continue
		var d := pos.distance_squared_to(rider["pos"])
		if d < best_dist:
			best_dist = d
			best = rider
	return best

func _nearest_team_rider(team: int, pos: Vector2) -> String:
	var best := ""
	var best_dist := INF
	for rider in state["riders"]:
		if int(rider["team"]) != team:
			continue
		var d := pos.distance_squared_to(rider["pos"])
		if d < best_dist:
			best_dist = d
			best = str(rider["id"])
	return best

func _best_pass_target(team: int, source_id: String) -> Dictionary:
	var source := _rider(source_id)
	var best := {}
	var best_x := -INF if team == 0 else INF
	for rider in state["riders"]:
		if int(rider["team"]) != team or str(rider["id"]) == source_id:
			continue
		if team == 0 and float(rider["pos"].x) > best_x:
			best_x = float(rider["pos"].x)
			best = rider
		elif team == 1 and float(rider["pos"].x) < best_x:
			best_x = float(rider["pos"].x)
			best = rider
	return best if not best.is_empty() else source

func _is_attacking_goal(team: int, pos: Vector2) -> bool:
	return pos.x > FIELD_SIZE.x * 0.72 if team == 0 else pos.x < FIELD_SIZE.x * 0.28

func _emit(type: String, message: String, payload: Dictionary = {}) -> void:
	var event := {"type": type, "message": message, "payload": payload}
	events.append(event)
	state["last_action"] = message
