extends Node

const SAVE_PATH := "user://chogan_save.json"
const BACKUP_PATH := "user://chogan_save.bak.json"
const SCHEMA_VERSION := 1
const RUN_STATE := preload("res://domain/run/run_state.gd")

var data: Dictionary = {
	"schema": SCHEMA_VERSION,
	"audio": {"master": 0.8, "muted": false},
	"match_speed": 1.0,
	"persian_digits": true,
	"last_seed": 1403,
	"last_lineup": [],
	"run": {},
	"meta": {"completed_runs": 0, "best_coins": 0, "tutorial_seen": false}
}

func set_run(run_state: RefCounted) -> void:
	data["run"] = run_state.to_dict()
	save()

func get_run() -> RefCounted:
	var run_data: Variant = data.get("run", {})
	if typeof(run_data) == TYPE_DICTIONARY and not run_data.is_empty():
		return RUN_STATE.from_dict(run_data)
	return null

func _ready() -> void:
	load_save()

func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema", -1)) != SCHEMA_VERSION:
		push_warning("Save file is invalid; defaults restored.")
		return
	data.merge(parsed, true)

func save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.get_file_as_string(SAVE_PATH)
		var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		if backup:
			backup.store_string(old)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
