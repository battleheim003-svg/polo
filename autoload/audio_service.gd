extends Node

var muted: bool = false
var master_volume: float = 0.8

func apply_settings() -> void:
	var settings: Dictionary = SaveService.data.get("audio", {})
	muted = bool(settings.get("muted", false))
	master_volume = float(settings.get("master", 0.8))
	AudioServer.set_bus_mute(0, muted)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
