class_name RuleAi
extends RefCounted

func choose_command(state: MatchState, team_index: int, team: TeamDefinition) -> String:
	var behind := state.scores[team_index] < state.scores[1 - team_index]
	var ahead := state.scores[team_index] > state.scores[1 - team_index]
	var owns_ball := state.ball.possession_team == team_index
	if team.ai_profile == "adaptive":
		if behind:
			return "counter" if owns_ball else "press"
		if owns_ball and state.ball.zone >= 4:
			return "counter"
		if owns_ball:
			return "safe_pass"
		if state.ball.line_owner_team == team_index:
			return "hold_line"
		if state.pressure[team_index] > 0.35:
			return "calm"
		return "press"
	if behind and state.time_remaining < 60:
		return "press"
	if ahead and state.time_remaining < 45:
		return "calm"
	if owns_ball and state.ball.zone >= 4:
		return "counter"
	if owns_ball:
		return "safe_pass"
	if team.ai_profile == "aggressive":
		return "press"
	return team.base_tactic
