class_name RiderDefinition
extends RefCounted

var id: String
var name_fa: String
var name_en: String
var preferred_role: String
var allowed_roles: Array[String]
var strike: int
var ride: int
var control: int
var focus: int
var trait_id: String
var skill: String
var horse_id: String

static func from_dict(data: Dictionary):
	var r := RiderDefinition.new()
	r.id = str(data.get("id", ""))
	r.name_fa = str(data.get("name_fa", ""))
	r.name_en = str(data.get("name_en", ""))
	r.preferred_role = str(data.get("preferred_role", ""))
	r.allowed_roles = []
	for role in data.get("allowed_roles", []):
		r.allowed_roles.append(str(role))
	r.strike = int(data.get("strike", 50))
	r.ride = int(data.get("ride", 50))
	r.control = int(data.get("control", 50))
	r.focus = int(data.get("focus", 50))
	r.trait_id = str(data.get("trait", ""))
	r.skill = str(data.get("skill", ""))
	r.horse_id = str(data.get("horse_id", ""))
	return r
