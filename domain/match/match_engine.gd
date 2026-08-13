class_name MatchEngine
extends RefCounted

const LINEUP_TOOLS := preload("res://domain/match/lineup_tools.gd")

var repo: DataRepository
var ai := RuleAi.new()

func _init(repository: DataRepository) -> void:
	repo = repository

func create_match(seed_value: int, player_team_id: String = "player", enemy_team_id: String = "enemy", player_lineup: Array[String] = []) -> MatchState:
	var state := MatchState.new()
	state.seed = seed_value
	state.rng_state = seed_value
	state.status = "running"
	var player: TeamDefinition = repo.teams[player_team_id]
	var enemy: TeamDefinition = repo.teams[enemy_team_id]
	var lineup := player_lineup if player_lineup.size() == 4 else player.rider_ids
	_add_team_riders(state, 0, lineup)
	_add_team_riders(state, 1, enemy.rider_ids)
	state.synergies[0] = LINEUP_TOOLS.active_synergies(repo, lineup)
	state.synergies[1] = LINEUP_TOOLS.active_synergies(repo, enemy.rider_ids)
	state.ball.zone = 3
	state.ball.possession_team = seed_value % 2
	state.ball.line_owner_team = state.ball.possession_team
	state.ball.holder_id = _first_rider_for_team(state, state.ball.possession_team)
	state.ball.controlled = true
	state.events.append(MatchEvent.new("ChukkerStarted", "Chukker 1 started.", {"chukker": 1}))
	state.events.append(MatchEvent.new("PossessionChanged", "Initial possession set.", {"team": state.ball.possession_team}))
	for team in [0, 1]:
		for synergy in state.synergies.get(team, []):
			state.events.append(MatchEvent.new("SynergyActivated", "%s active." % synergy["name"], {"team": team, "synergy": synergy.duplicate()}))
	return state

func simulate_tick(state: MatchState, commands: Array[String]) -> Array[MatchEvent]:
	if state.status == "ended":
		return []
	if state.status == "between_chukkers":
		state.substitution_pending = true
		return [MatchEvent.new("SubstitutionRequested", "Choose a break decision.", {"team": 0})]
	var rng := DeterministicRng.new(_tick_seed(state, 0))
	var batch: Array[MatchEvent] = []
	state.tick_index += 1
	state.skill_tick_guard.clear()
	var player_command := _resolve_player_command(state, commands[0] if commands.size() > 0 else state.active_command, batch)
	var enemy_team: TeamDefinition = repo.teams["enemy"]
	var enemy_command := ai.choose_command(state, 1, enemy_team)
	var action := _choose_action(state)
	_resolve_action(state, rng, action, player_command, enemy_command, batch)
	_update_condition(state, batch)
	_advance_clock(state, batch)
	state.rng_state = _tick_seed(state, 999)
	for e in batch:
		state.events.append(e)
	return batch

func resolve_break_decision(state: MatchState, decision: String = "rest") -> Array[MatchEvent]:
	var batch: Array[MatchEvent] = []
	if not state.substitution_pending:
		return batch
	if decision == "swap":
		for rider in state.riders:
			if int(rider["team"]) == 0 and int(rider["stamina"]) < 55:
				rider["stamina"] = mini(100, int(rider["stamina"]) + 20)
				rider["focus"] = mini(BalanceConfig.MAX_FOCUS, int(rider["focus"]) + 6)
		state.substitutions_applied += 1
		batch.append(MatchEvent.new("SubstitutionApplied", "Break substitution applied.", {"count": state.substitutions_applied}))
	else:
		for rider in state.riders:
			if int(rider["team"]) in [0, 1]:
				rider["stamina"] = mini(100, int(rider["stamina"]) + 8)
				rider["focus"] = mini(BalanceConfig.MAX_FOCUS, int(rider["focus"]) + 4)
		batch.append(MatchEvent.new("BreakRestApplied", "Lineups kept; focus restored.", {"team": -1}))
	state.substitution_pending = false
	state.pending_substitution_team = -1
	state.status = "running"
	batch.append(MatchEvent.new("ChukkerResumed", "Next chukker resumed.", {"decision": decision}))
	for e in batch:
		state.events.append(e)
	return batch

func run_to_end(seed_value: int, player_command: String = "hold_line") -> MatchState:
	var state := create_match(seed_value)
	var guard := 0
	while state.status != "ended" and guard < 500:
		if state.status == "between_chukkers":
			state.substitution_pending = true
			resolve_break_decision(state, "rest")
		elif state.substitution_pending:
			resolve_break_decision(state, "rest")
		else:
			simulate_tick(state, [player_command])
		guard += 1
	if guard >= 500:
		state.status = "ended"
		state.events.append(MatchEvent.new("MatchEnded", "Match ended by loop guard.", {"reason": "guard"}))
	return state

func _add_team_riders(state: MatchState, team_index: int, ids: Array[String]) -> void:
	for slot in range(ids.size()):
		var rider: RiderDefinition = repo.riders[ids[slot]]
		var horse: HorseDefinition = repo.horses[rider.horse_id]
		state.riders.append({
			"id": rider.id, "team": team_index, "slot": slot, "role": LINEUP_TOOLS.role_for_slot(slot),
			"stamina": BalanceConfig.MAX_STAMINA, "focus": rider.focus, "actions_this_tick": []
		})
		state.horses[rider.id] = {"id": horse.id, "stamina": horse.stamina, "condition": 1.0}

func _resolve_player_command(state: MatchState, requested: String, batch: Array[MatchEvent]) -> String:
	if state.command_ticks_remaining > 0:
		state.command_ticks_remaining -= 1
		return state.active_command
	var key := "%d:%d:%s" % [0, state.chukker, requested]
	if int(state.command_uses.get(key, 0)) >= BalanceConfig.COMMANDS_PER_CHUKKER:
		return state.active_command
	state.command_uses[key] = int(state.command_uses.get(key, 0)) + 1
	state.active_command = requested
	state.command_ticks_remaining = BalanceConfig.COMMAND_DURATION_TICKS - 1
	batch.append(MatchEvent.new("CoachCommandActivated", "Coach command: %s" % _tactic_name(requested), {"team": 0, "command": requested, "duration": BalanceConfig.COMMAND_DURATION_TICKS}))
	return requested

func _choose_action(state: MatchState) -> String:
	if not state.ball.controlled:
		return BalanceConfig.ACTION_RECOVERY
	if (state.ball.zone == 5 and state.ball.possession_team == 0) or (state.ball.zone == 1 and state.ball.possession_team == 1):
		return BalanceConfig.ACTION_SHOT
	var roll := int(DeterministicRng.value(state.seed, state.tick_index * 10 + 1) * 100.0)
	if roll < 16:
		return BalanceConfig.ACTION_HOOK
	if roll < 30:
		return BalanceConfig.ACTION_RIDE_OFF
	if roll < 50:
		return BalanceConfig.ACTION_PASS
	return BalanceConfig.ACTION_STRIKE

func _resolve_action(state: MatchState, rng: DeterministicRng, action: String, player_command: String, enemy_command: String, batch: Array[MatchEvent]) -> void:
	var team := state.ball.possession_team if state.ball.possession_team >= 0 else int(rng.next_int() % 2)
	var actor := _best_rider(state, team, action)
	_mark_action(actor, action)
	var dominance := _dominance(state, actor, action, player_command if team == 0 else enemy_command)
	var opponent := _best_rider(state, 1 - team, BalanceConfig.ACTION_HOOK)
	var opposition := _dominance(state, opponent, BalanceConfig.ACTION_HOOK, enemy_command if team == 0 else player_command)
	match action:
		BalanceConfig.ACTION_HOOK:
			state.stats["hooks"] += 1
			if opposition + _variance(state, 2, -8, 8) > dominance - 6:
				state.ball.controlled = false
				state.pressure[team] = minf(1.0, state.pressure[team] + 0.08)
				batch.append(MatchEvent.new("HookPerformed", "Successful hook disrupted control.", {"team": 1 - team, "pressure": state.pressure[team]}))
			else:
				batch.append(MatchEvent.new("HookPerformed", "Hook failed.", {"team": 1 - team}))
		BalanceConfig.ACTION_RIDE_OFF:
			state.stats["ride_offs"] += 1
			if opposition + _variance(state, 3, -6, 6) > dominance - 4:
				state.ball.line_owner_team = 1 - team
				batch.append(MatchEvent.new("LineOwnerChanged", "Ride-off changed line owner.", {"line_owner": state.ball.line_owner_team, "reason": "ride_off"}))
			else:
				batch.append(MatchEvent.new("RideOffPerformed", "Ride-off defended.", {"line_owner": state.ball.line_owner_team}))
		BalanceConfig.ACTION_PASS:
			state.stats["passes"] += 1
			if dominance > opposition * 0.82:
				state.ball.holder_id = _next_rider_for_team(state, team, str(actor["id"]))
				state.ball.line_owner_team = team
				state.ball.controlled = true
				batch.append(MatchEvent.new("PassPerformed", "Clean pass transferred line ownership.", {"holder": state.ball.holder_id, "line_owner": team}))
				_apply_midfield_whirl(state, team, batch)
			else:
				state.ball.controlled = false
				batch.append(MatchEvent.new("PassPerformed", "Pass failed.", {"holder": ""}))
		BalanceConfig.ACTION_RECOVERY:
			state.stats["recoveries"] += 1
			var recover_team := 0 if dominance >= opposition else 1
			state.ball.possession_team = recover_team
			state.ball.line_owner_team = recover_team
			state.ball.holder_id = str(_best_rider(state, recover_team, BalanceConfig.ACTION_RECOVERY)["id"])
			state.ball.controlled = true
			batch.append(MatchEvent.new("BallRecovered", "Loose ball recovered.", {"team": recover_team, "line_owner": recover_team}))
		BalanceConfig.ACTION_SHOT:
			state.stats["shots"] += 1
			batch.append(MatchEvent.new("ShotAttempted", "Shot attempted.", {"team": team, "dominance": dominance}))
			if dominance + _variance(state, 4, -10, 10) > BalanceConfig.SHOT_THRESHOLD:
				state.scores[team] += 1
				state.stats["goals"] += 1
				state.ball.attack_direction *= -1
				state.ball.zone = 3
				state.ball.possession_team = 1 - team
				state.ball.line_owner_team = 1 - team
				state.ball.holder_id = _first_rider_for_team(state, 1 - team)
				state.ball.controlled = true
				batch.append(MatchEvent.new("GoalScored", "Goal scored; restart reset the line.", {"team": team, "scores": state.scores.duplicate(), "attack_direction": state.ball.attack_direction, "line_owner": state.ball.line_owner_team}))
			else:
				state.ball.controlled = false
		_:
			state.stats["strikes"] += 1
			var delta := 1 if team == 0 else -1
			if dominance > opposition * 0.78:
				state.ball.zone = clampi(state.ball.zone + delta * state.ball.attack_direction, 1, 5)
				batch.append(MatchEvent.new("StrikePerformed", "Strike advanced the ball.", {"zone": state.ball.zone, "dominance": dominance}))
				batch.append(MatchEvent.new("BallAdvanced", "Ball is in zone %d." % state.ball.zone, {"zone": state.ball.zone}))
			else:
				state.ball.zone = clampi(state.ball.zone - delta * state.ball.attack_direction, 1, 5)
				batch.append(MatchEvent.new("StrikePerformed", "Strike was forced back.", {"zone": state.ball.zone, "dominance": dominance}))
				batch.append(MatchEvent.new("BallRetreated", "Ball retreated.", {"zone": state.ball.zone}))
	_maybe_foul(state, batch)
	_maybe_skill(state, actor, action, batch)

func _dominance(state: MatchState, actor: Dictionary, action: String, command: String) -> float:
	var rider: RiderDefinition = repo.riders[actor["id"]]
	var horse: HorseDefinition = repo.horses[rider.horse_id]
	var stat := rider.control
	if action in [BalanceConfig.ACTION_STRIKE, BalanceConfig.ACTION_SHOT]:
		stat = rider.strike
	elif action == BalanceConfig.ACTION_RIDE_OFF:
		stat = rider.ride
	var role := str(actor["role"])
	var role_fit := LINEUP_TOOLS.role_fit(rider, role)
	var horse_condition := float(actor["stamina"]) / 100.0 * 0.55 + float(horse.coordination + horse.calmness) / 200.0 * 0.45
	var zone_bonus := BalanceConfig.ZONE_BONUS if _role_zone(role) == state.ball.zone else 0.0
	var tactic_bonus := _tactic_bonus(command, action)
	var line_bonus := BalanceConfig.LINE_OWNER_BONUS if state.ball.line_owner_team == int(actor["team"]) else 0.0
	var synergy_bonus := _synergy_bonus(state, int(actor["team"]), action)
	var fatigue := (100.0 - float(actor["stamina"])) / 100.0 * BalanceConfig.FATIGUE_WEIGHT
	var pressure_penalty := state.pressure[1 - int(actor["team"])] * BalanceConfig.PRESSURE_WEIGHT
	var variance := _variance(state, 5 + int(actor["slot"]), -BalanceConfig.VARIANCE, BalanceConfig.VARIANCE)
	var total := stat * role_fit * horse_condition + zone_bonus + tactic_bonus + line_bonus + synergy_bonus - fatigue - pressure_penalty + variance
	state.dominance_breakdowns.append({
		"tick": state.tick_index, "rider": actor["id"], "team": actor["team"], "action": action,
		"role_fit": role_fit, "horse_condition": horse_condition, "zone_bonus": zone_bonus,
		"tactic_bonus": tactic_bonus, "line_owner_bonus": line_bonus, "synergy_bonus": synergy_bonus,
		"fatigue": fatigue, "pressure_penalty": pressure_penalty, "variance": variance, "total": total
	})
	if state.dominance_breakdowns.size() > 20:
		state.dominance_breakdowns.pop_front()
	return total

func _synergy_bonus(state: MatchState, team: int, action: String) -> float:
	var synergies: Array = state.synergies.get(team, [])
	var bonus := 0.0
	if LINEUP_TOOLS.has_synergy(synergies, "wall_and_spear") and action == BalanceConfig.ACTION_SHOT:
		bonus += 3.0
	if LINEUP_TOOLS.has_synergy(synergies, "fearless_team") and action in [BalanceConfig.ACTION_STRIKE, BalanceConfig.ACTION_SHOT]:
		bonus += 2.0
	return minf(bonus, BalanceConfig.SYNERGY_CAP)

func _apply_midfield_whirl(state: MatchState, team: int, batch: Array[MatchEvent]) -> void:
	if state.ball.zone != 3 or not LINEUP_TOOLS.has_synergy(state.synergies.get(team, []), "midfield_whirl"):
		return
	for rider in state.riders:
		if int(rider["team"]) == team and str(rider["id"]) in ["bal-ro", "meydan-dar"]:
			rider["focus"] = clampi(int(rider["focus"]) + 3, 0, BalanceConfig.MAX_FOCUS)
	batch.append(MatchEvent.new("SynergyEffectApplied", "Midfield Whirl generated focus.", {"team": team, "synergy": "midfield_whirl"}))

func _update_condition(state: MatchState, batch: Array[MatchEvent]) -> void:
	for rider in state.riders:
		var old_stamina := int(rider["stamina"])
		var old_focus := int(rider["focus"])
		var slot := int(rider["slot"])
		var drain := 1 + int(DeterministicRng.value(state.seed, state.tick_index * 100 + slot) > 0.74)
		var rider_def: RiderDefinition = repo.riders[rider["id"]]
		var fit_ok := LINEUP_TOOLS.role_fit(rider_def, str(rider["role"])) >= BalanceConfig.ROLE_ADJACENT
		if fit_ok and LINEUP_TOOLS.has_synergy(state.synergies.get(int(rider["team"]), []), "matched_horses") and DeterministicRng.value(state.seed, state.tick_index * 100 + slot + 7) > 0.78:
			drain = maxi(0, drain - 1)
		rider["stamina"] = maxi(0, old_stamina - drain)
		rider["focus"] = clampi(old_focus + (-1 if DeterministicRng.value(state.seed, state.tick_index * 100 + slot + 40) < 0.42 else 1), 0, BalanceConfig.MAX_FOCUS)
		if int(rider["stamina"]) != old_stamina:
			batch.append(MatchEvent.new("StaminaChanged", "Stamina changed.", {"rider": rider["id"], "value": rider["stamina"]}))
		if int(rider["focus"]) != old_focus:
			batch.append(MatchEvent.new("FocusChanged", "Focus changed.", {"rider": rider["id"], "value": rider["focus"]}))

func _advance_clock(state: MatchState, batch: Array[MatchEvent]) -> void:
	state.time_remaining -= BalanceConfig.TICK_SECONDS
	if state.time_remaining > 0:
		return
	if not state.chukker_end_emitted.has(state.chukker):
		state.chukker_end_emitted[state.chukker] = true
		batch.append(MatchEvent.new("ChukkerEnded", "Chukker %d ended." % state.chukker, {"chukker": state.chukker}))
	if state.chukker < BalanceConfig.CHUKKER_COUNT:
		state.chukker += 1
		state.time_remaining = BalanceConfig.CHUKKER_SECONDS
		state.status = "between_chukkers"
		batch.append(MatchEvent.new("ChukkerStarted", "Chukker %d ready." % state.chukker, {"chukker": state.chukker}))
	elif state.scores[0] == state.scores[1] and state.extra_ticks < BalanceConfig.MAX_EXTRA_TICKS:
		state.extra_ticks += 1
		state.time_remaining = BalanceConfig.TICK_SECONDS
	else:
		if state.scores[0] == state.scores[1]:
			var winner := _tie_break_winner(state)
			state.scores[winner] += 1
			batch.append(MatchEvent.new("TieBreakResolved", "Tie-break resolved the match.", {"team": winner, "reason": "advantage"}))
		state.status = "ended"
		batch.append(MatchEvent.new("MatchEnded", "Match ended.", {"scores": state.scores.duplicate(), "reason": "time"}))

func _maybe_foul(state: MatchState, batch: Array[MatchEvent]) -> void:
	var holder := _rider_state(state, state.ball.holder_id)
	var rider: RiderDefinition = repo.riders.get(str(holder.get("id", "")))
	var horse: HorseDefinition = repo.horses.get(rider.horse_id) if rider != null else null
	var control_factor := (100.0 - float(rider.control if rider != null else 60)) / 1000.0
	var calm_factor := (100.0 - float(horse.calmness if horse != null else 70)) / 1200.0
	var fatigue_factor := (100.0 - float(holder.get("stamina", 80))) / 1400.0
	var command_factor := -0.01 if state.active_command == "calm" else 0.012 if state.active_command == "press" else 0.0
	var synergy_factor := 0.012 if LINEUP_TOOLS.has_synergy(state.synergies.get(state.ball.possession_team, []), "fearless_team") else 0.0
	var chance := clampf(0.018 + control_factor + calm_factor + fatigue_factor + command_factor + synergy_factor + state.pressure[state.ball.possession_team] * 0.02, 0.005, 0.12)
	if DeterministicRng.value(state.seed, state.tick_index * 10 + 6) < chance:
		state.stats["fouls"] += 1
		state.ball.controlled = true
		state.ball.possession_team = 1 - state.ball.possession_team
		state.ball.line_owner_team = state.ball.possession_team
		state.ball.holder_id = _first_rider_for_team(state, state.ball.possession_team)
		batch.append(MatchEvent.new("FoulCommitted", "Foul changed possession.", {"team": 1 - state.ball.possession_team, "chance": chance}))
		batch.append(MatchEvent.new("FreeHitAwarded", "Free hit awarded with line ownership.", {"team": state.ball.possession_team, "line_owner": state.ball.line_owner_team}))

func _maybe_skill(state: MatchState, actor: Dictionary, action: String, batch: Array[MatchEvent]) -> void:
	if state.skill_tick_guard.has(actor["id"]):
		return
	var rider: RiderDefinition = repo.riders[actor["id"]]
	var chance := 0.08 + float(actor["focus"]) / 1200.0
	if DeterministicRng.value(state.seed, state.tick_index * 10 + 7 + int(actor["slot"])) >= chance:
		return
	state.skill_tick_guard[actor["id"]] = true
	state.stats["skills"] += 1
	var effect := _apply_skill_effect(state, actor, rider, action)
	batch.append(MatchEvent.new("SkillActivated", "%s activated." % rider.skill, {"rider": actor["id"], "skill": rider.skill, "action": action, "effect": effect}))

func _apply_skill_effect(state: MatchState, actor: Dictionary, rider: RiderDefinition, action: String) -> String:
	match rider.id:
		"pish-taz":
			if action == BalanceConfig.ACTION_SHOT:
				state.pressure[1 - int(actor["team"])] += 0.08
				return "golden_shot_pressure"
		"bal-ro":
			state.ball.zone = clampi(state.ball.zone + (1 if int(actor["team"]) == 0 else -1) * state.ball.attack_direction, 1, 5)
			return "lane_surge"
		"meydan-dar":
			actor["focus"] = clampi(int(actor["focus"]) + 8, 0, BalanceConfig.MAX_FOCUS)
			return "field_read_focus"
		"dejban":
			state.ball.line_owner_team = int(actor["team"])
			return "line_lock"
		"tond-taz":
			actor["stamina"] = clampi(int(actor["stamina"]) + 6, 0, BalanceConfig.MAX_STAMINA)
			return "sprint_recovery"
		"aram-ran":
			for rider_state in state.riders:
				if int(rider_state["team"]) == int(actor["team"]):
					rider_state["focus"] = clampi(int(rider_state["focus"]) + 3, 0, BalanceConfig.MAX_FOCUS)
			return "team_breath"
	actor["focus"] = clampi(int(actor["focus"]) + 5, 0, BalanceConfig.MAX_FOCUS)
	return "focus"

func _best_rider(state: MatchState, team: int, action: String) -> Dictionary:
	var best := {}
	var best_score := -999
	for rider_state in state.riders:
		if int(rider_state["team"]) != team:
			continue
		var rider: RiderDefinition = repo.riders[rider_state["id"]]
		var score := rider.control
		if action in [BalanceConfig.ACTION_STRIKE, BalanceConfig.ACTION_SHOT]:
			score = rider.strike
		elif action == BalanceConfig.ACTION_RIDE_OFF:
			score = rider.ride
		score += int(rider_state["stamina"]) / 4 + int(rider_state["focus"]) / 5
		if score > best_score:
			best = rider_state
			best_score = score
	return best

func _mark_action(actor: Dictionary, action: String) -> void:
	actor["actions_this_tick"] = [action]

func _first_rider_for_team(state: MatchState, team: int) -> String:
	for rider in state.riders:
		if int(rider["team"]) == team:
			return str(rider["id"])
	return ""

func _next_rider_for_team(state: MatchState, team: int, current_id: String) -> String:
	var ids: Array[String] = []
	for rider in state.riders:
		if int(rider["team"]) == team:
			ids.append(str(rider["id"]))
	var idx := ids.find(current_id)
	return ids[(idx + 1) % ids.size()] if ids.size() > 0 else current_id

func _rider_state(state: MatchState, rider_id: String) -> Dictionary:
	for rider in state.riders:
		if str(rider["id"]) == rider_id:
			return rider
	return {}

func _tie_break_winner(state: MatchState) -> int:
	var player_total := _team_condition_score(state, 0)
	var enemy_total := _team_condition_score(state, 1)
	if is_equal_approx(player_total, enemy_total):
		return state.seed % 2
	return 0 if player_total > enemy_total else 1

func _team_condition_score(state: MatchState, team: int) -> float:
	var total := 0.0
	for rider in state.riders:
		if int(rider["team"]) == team:
			total += float(rider["stamina"]) * 0.55 + float(rider["focus"]) * 0.45
	total += 3.0 if state.ball.line_owner_team == team else 0.0
	total += 2.0 if state.ball.possession_team == team else 0.0
	return total

func _role_zone(role: String) -> int:
	match role:
		"guardian": return 2
		"midfielder": return 3
		"attacker": return 4
		"runner": return 5
		_: return 3

func _tactic_bonus(command: String, action: String) -> float:
	if command == "press" and action in [BalanceConfig.ACTION_HOOK, BalanceConfig.ACTION_RIDE_OFF]:
		return BalanceConfig.TACTIC_BONUS
	if command == "hold_line" and action == BalanceConfig.ACTION_STRIKE:
		return BalanceConfig.TACTIC_BONUS
	if command == "safe_pass" and action == BalanceConfig.ACTION_PASS:
		return BalanceConfig.TACTIC_BONUS
	if command == "counter" and action == BalanceConfig.ACTION_SHOT:
		return BalanceConfig.TACTIC_BONUS
	if command == "calm" and action == BalanceConfig.ACTION_RECOVERY:
		return BalanceConfig.TACTIC_BONUS
	return 0.0

func _tactic_name(command: String) -> String:
	return str(repo.tactics.get(command, {"name_fa": command}).get("name_fa", command))

func _tick_seed(state: MatchState, salt: int) -> int:
	return int(DeterministicRng.value(state.seed, state.tick_index * 1000 + salt) * 2147483647.0)

func _variance(state: MatchState, salt: int, min_value: float, max_value: float) -> float:
	return DeterministicRng.range_value(state.seed, state.tick_index * 100 + salt, min_value, max_value)
