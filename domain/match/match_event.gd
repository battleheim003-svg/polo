class_name MatchEvent
extends RefCounted

var type: String
var message: String
var payload: Dictionary

func _init(event_type: String = "", event_message: String = "", event_payload: Dictionary = {}) -> void:
	type = event_type
	message = event_message
	payload = event_payload.duplicate(true)

func to_dict() -> Dictionary:
	return {"type": type, "message": message, "payload": payload}
