extends SceneTree

const MATCHES := 1000
const OUT_PATH := "res://balance_report.json"

func _init() -> void:
	var repo := DataRepository.new()
	if not repo.load_all():
		quit(1)
		return
	var engine := MatchEngine.new(repo)
	var rows: Array[Dictionary] = []
	var wins := [0, 0]
	var draws := 0
	var totals := {
		"goals":0, "fouls":0, "hooks":0, "ride_offs":0, "passes":0, "skills":0,
		"shots":0, "strikes":0, "recoveries":0, "length":0, "extra":0
	}
	var event_totals := {"free_hits":0, "possession_changes":0, "line_owner_changes":0, "synergy_effects":0}
	for i in range(MATCHES):
		var seed := 10000 + i
		var state := engine.run_to_end(seed, "hold_line")
		var winner := "draw"
		if state.scores[0] > state.scores[1]:
			winner = "player"
			wins[0] += 1
		elif state.scores[1] > state.scores[0]:
			winner = "enemy"
			wins[1] += 1
		else:
			draws += 1
		for key in ["goals", "fouls", "hooks", "ride_offs", "passes", "skills", "shots", "strikes", "recoveries"]:
			totals[key] += int(state.stats[key])
		if state.extra_ticks > 0:
			totals["extra"] += 1
		for event in state.events:
			if event.type == "FreeHitAwarded":
				event_totals["free_hits"] += 1
			elif event.type == "PossessionChanged":
				event_totals["possession_changes"] += 1
			elif event.type == "LineOwnerChanged":
				event_totals["line_owner_changes"] += 1
			elif event.type == "SynergyEffectApplied":
				event_totals["synergy_effects"] += 1
		var duration := BalanceConfig.CHUKKER_COUNT * BalanceConfig.CHUKKER_SECONDS + state.extra_ticks * BalanceConfig.TICK_SECONDS
		totals["length"] += duration
		rows.append({
			"seed": seed,
			"lineup": repo.teams["player"].rider_ids,
			"role_assignments": _role_assignments(state),
			"horse_ids": _horse_ids(repo, repo.teams["player"].rider_ids),
			"synergies": state.synergies,
			"commands": state.command_uses,
			"winner": winner,
			"score": state.scores,
			"end_reason": "time",
			"logical_duration": duration,
			"extra_time": state.extra_ticks > 0,
			"action_counts": state.stats.duplicate(true),
			"foul_count": state.stats["fouls"],
			"skill_activations": state.stats["skills"],
			"stamina_remaining": _stamina_remaining(state),
			"comeback": _comeback(state)
		})
	var player_rate := float(wins[0]) / MATCHES
	var enemy_rate := float(wins[1]) / MATCHES
	var summary := {
		"matches": MATCHES,
		"player_win_rate": player_rate,
		"enemy_win_rate": enemy_rate,
		"draw_rate": float(draws) / MATCHES,
		"win_rate_difference": abs(player_rate - enemy_rate),
		"average_goals": float(totals["goals"]) / MATCHES,
		"average_length": float(totals["length"]) / MATCHES,
		"extra_time_rate": float(totals["extra"]) / MATCHES,
		"foul_rate": float(totals["fouls"]) / MATCHES,
		"action_frequency": {
			"strikes": totals["strikes"], "passes": totals["passes"], "hooks": totals["hooks"],
			"ride_offs": totals["ride_offs"], "recoveries": totals["recoveries"], "shots": totals["shots"],
			"goals": totals["goals"], "fouls": totals["fouls"], "free_hits": event_totals["free_hits"],
			"possession_changes": event_totals["possession_changes"], "line_owner_changes": event_totals["line_owner_changes"]
		},
		"skill_activation_rate": float(totals["skills"]) / MATCHES,
		"synergy_effects": event_totals["synergy_effects"]
	}
	var report := {"summary": summary, "matches": rows}
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(summary))
	quit(0)

func _role_assignments(state: MatchState) -> Dictionary:
	var result := {}
	for rider in state.riders:
		if int(rider["team"]) == 0:
			result[str(rider["id"])] = str(rider["role"])
	return result

func _horse_ids(repo: DataRepository, rider_ids: Array[String]) -> Dictionary:
	var result := {}
	for rider_id in rider_ids:
		var rider: RiderDefinition = repo.riders[rider_id]
		result[rider_id] = rider.horse_id
	return result

func _stamina_remaining(state: MatchState) -> Dictionary:
	var result := {}
	for rider in state.riders:
		result[str(rider["id"])] = int(rider["stamina"])
	return result

func _comeback(state: MatchState) -> bool:
	return state.scores[0] != state.scores[1] and state.extra_ticks > 0
