class_name DataRepository
extends RefCounted

const RIDER_DEFINITION := preload("res://domain/match/rider_definition.gd")
const HORSE_DEFINITION := preload("res://domain/match/horse_definition.gd")
const TEAM_DEFINITION := preload("res://domain/match/team_definition.gd")

var riders: Dictionary = {}
var horses: Dictionary = {}
var teams: Dictionary = {}
var tactics: Dictionary = {}

func _init() -> void:
	riders = {}
	horses = {}
	teams = {}
	tactics = {}

func load_all() -> bool:
	riders = _load_list("res://data/riders/riders.json", RIDER_DEFINITION)
	horses = _load_list("res://data/horses/horses.json", HORSE_DEFINITION)
	teams = _load_list("res://data/teams/teams.json", TEAM_DEFINITION)
	tactics = _load_json_array("res://data/tactics/tactics.json")
	return validate()

func validate() -> bool:
	if riders.size() < 6 or horses.size() < 4 or teams.size() < 2 or tactics.size() < 5:
		push_error("Prototype data is incomplete.")
		return false
	for team in teams.values():
		if team.rider_ids.size() != 4:
			push_error("Team %s must contain exactly four riders." % team.id)
			return false
		for rider_id in team.rider_ids:
			if not riders.has(rider_id):
				push_error("Team %s references missing rider %s." % [team.id, rider_id])
				return false
	for rider in riders.values():
		if not horses.has(rider.horse_id):
			push_error("Rider %s references missing horse %s." % [rider.id, rider.horse_id])
			return false
	return true

func _load_list(path: String, klass: Variant) -> Dictionary:
	var result: Dictionary = {}
	for item in _read_json(path):
		var obj = klass.from_dict(item)
		result[obj.id] = obj
	return result

func _load_json_array(path: String) -> Dictionary:
	var result: Dictionary = {}
	for item in _read_json(path):
		result[str(item.get("id", ""))] = item
	return result

func _read_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: %s" % path)
		return []
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Invalid JSON array: %s" % path)
		return []
	return parsed
