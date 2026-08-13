class_name TeamDefinition
extends RefCounted

var id: String
var name: String
var rider_ids: Array[String]
var base_tactic: String
var ai_profile: String

static func from_dict(data: Dictionary):
	var t := TeamDefinition.new()
	t.id = str(data.get("id", ""))
	t.name = str(data.get("name", ""))
	t.rider_ids = []
	for rider_id in data.get("rider_ids", []):
		t.rider_ids.append(str(rider_id))
	t.base_tactic = str(data.get("base_tactic", "hold_line"))
	t.ai_profile = str(data.get("ai_profile", "balanced"))
	return t
