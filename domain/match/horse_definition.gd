class_name HorseDefinition
extends RefCounted

var id: String
var name: String
var speed: int
var stamina: int
var calmness: int
var coordination: int
var trait_id: String

static func from_dict(data: Dictionary):
	var h := HorseDefinition.new()
	h.id = str(data.get("id", ""))
	h.name = str(data.get("name", ""))
	h.speed = int(data.get("speed", 50))
	h.stamina = int(data.get("stamina", 50))
	h.calmness = int(data.get("calmness", 50))
	h.coordination = int(data.get("coordination", 50))
	h.trait_id = str(data.get("trait", ""))
	return h
