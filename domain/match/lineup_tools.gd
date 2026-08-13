class_name LineupTools
extends RefCounted

const ROLES: Array[String] = ["attacker", "runner", "midfielder", "guardian"]

static func role_for_slot(slot: int) -> String:
	if slot >= 0 and slot < ROLES.size():
		return ROLES[slot]
	return "midfielder"

static func role_fit(rider: RiderDefinition, role: String) -> float:
	if role == rider.preferred_role:
		return BalanceConfig.ROLE_EXACT
	if rider.allowed_roles.has(role):
		return BalanceConfig.ROLE_ADJACENT
	return BalanceConfig.ROLE_MISMATCH

static func role_fit_label(rider: RiderDefinition, role: String) -> String:
	var fit := role_fit(rider, role)
	if fit >= BalanceConfig.ROLE_EXACT:
		return "Good"
	if fit >= BalanceConfig.ROLE_ADJACENT:
		return "Acceptable"
	return "Poor"

static func validate_lineup(repo: DataRepository, rider_ids: Array[String]) -> Dictionary:
	if rider_ids.size() != 4:
		return {"ok": false, "reason": "Lineup must have exactly four slots."}
	var seen := {}
	var has_guardian := false
	for i in range(rider_ids.size()):
		var rider_id := rider_ids[i]
		if rider_id == "":
			return {"ok": false, "reason": "Slot %d is empty." % [i + 1]}
		if seen.has(rider_id):
			return {"ok": false, "reason": "Rider %s is duplicated." % rider_id}
		if not repo.riders.has(rider_id):
			return {"ok": false, "reason": "Missing rider %s." % rider_id}
		var rider: RiderDefinition = repo.riders[rider_id]
		if not repo.horses.has(rider.horse_id):
			return {"ok": false, "reason": "Rider %s has missing horse." % rider_id}
		if role_fit(rider, role_for_slot(i)) >= BalanceConfig.ROLE_ADJACENT and role_for_slot(i) == "guardian":
			has_guardian = true
		seen[rider_id] = true
	if not has_guardian:
		return {"ok": false, "reason": "Slot 4 needs a guardian-capable rider."}
	return {"ok": true, "reason": "Lineup is valid."}

static func active_synergies(repo: DataRepository, rider_ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if rider_ids.size() != 4:
		return result
	if rider_ids[0] == "pish-taz" and rider_ids[3] == "dejban":
		result.append({"id": "wall_and_spear", "name": "Wall and Spear", "effect": "First counter shot each chukker gains bonus."})
	if rider_ids.has("bal-ro") and rider_ids.has("meydan-dar"):
		result.append({"id": "midfield_whirl", "name": "Midfield Whirl", "effect": "Successful zone 3 passes build focus."})
	var horse_traits := {}
	for rider_id in rider_ids:
		if repo.riders.has(rider_id):
			var rider: RiderDefinition = repo.riders[rider_id]
			var horse: HorseDefinition = repo.horses.get(rider.horse_id)
			if horse != null:
				horse_traits[horse.trait_id] = int(horse_traits.get(horse.trait_id, 0)) + 1
	for trait_id in horse_traits.keys():
		if int(horse_traits[trait_id]) >= 2:
			result.append({"id": "matched_horses", "name": "Matched Horses", "effect": "Shared horse trait reduces stamina drain."})
			break
	var aggressive := 0
	for rider_id in rider_ids:
		if repo.riders.has(rider_id):
			var rider: RiderDefinition = repo.riders[rider_id]
			if rider.preferred_role in ["attacker", "runner"] or rider.trait_id in ["sharp_eye", "burst", "wide_lane"]:
				aggressive += 1
	if aggressive >= 3:
		result.append({"id": "fearless_team", "name": "Fearless Team", "effect": "Strike and shot gain power, foul risk rises."})
	return result

static func has_synergy(synergies: Array[Dictionary], synergy_id: String) -> bool:
	for synergy in synergies:
		if str(synergy.get("id", "")) == synergy_id:
			return true
	return false
