class_name BallState
extends RefCounted

var zone: int = 3
var possession_team: int = -1
var holder_id: String = ""
var line_owner_team: int = -1
var attack_direction: int = 1
var controlled: bool = false

func _init() -> void:
	zone = 3
	possession_team = -1
	holder_id = ""
	line_owner_team = -1
	attack_direction = 1
	controlled = false

func duplicate_state() -> BallState:
	var b := BallState.new()
	b.zone = zone
	b.possession_team = possession_team
	b.holder_id = holder_id
	b.line_owner_team = line_owner_team
	b.attack_direction = attack_direction
	b.controlled = controlled
	return b
