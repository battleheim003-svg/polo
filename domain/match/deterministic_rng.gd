class_name DeterministicRng
extends RefCounted

var state: int

func _init(seed_value: int = 1) -> void:
	state = seed_value & 0x7fffffff
	if state == 0:
		state = 1

func next_int() -> int:
	state = int((1103515245 * state + 12345) & 0x7fffffff)
	return state

func randf() -> float:
	return float(next_int()) / 2147483647.0

func rangef(min_value: float, max_value: float) -> float:
	return min_value + (max_value - min_value) * randf()

func pick(items: Array) -> Variant:
	if items.is_empty():
		return null
	return items[next_int() % items.size()]

func clone() -> DeterministicRng:
	var rng := DeterministicRng.new(1)
	rng.state = state
	return rng

static func value(seed_value: int, salt: int) -> float:
	var mixed := int((1103515245 * ((seed_value + salt * 374761393) & 0x7fffffff) + 12345) & 0x7fffffff)
	if mixed == 0:
		mixed = 1
	return float(mixed) / 2147483647.0

static func range_value(seed_value: int, salt: int, min_value: float, max_value: float) -> float:
	return min_value + (max_value - min_value) * value(seed_value, salt)
