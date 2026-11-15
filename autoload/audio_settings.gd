extends Node
## Volume options (autoload "AudioSettings"), saved in the `[audio]`
## section of `user://settings.cfg`.
##
## Each option drives one bus from `default_bus_layout.tres`. Music,
## Effects and Voice all feed Master, so Master scales everything. Sounds
## pick their bus with `AudioStreamPlayer.bus`. 0% mutes the bus.

signal changed

const SECTION := "audio"
const BUSES: Array[StringName] = [&"Master", &"Music", &"Effects", &"Voice"]
const STEP := 10

## Percent per bus name.
var volumes := {}


func _ready() -> void:
	var saved := SettingsFile.load_section(SECTION)
	for bus in BUSES:
		volumes[bus] = clampi(int(saved.get(String(bus), 100)), 0, 100)
		_apply(bus)


func get_volume(bus: StringName) -> int:
	return volumes.get(bus, 100)


func set_volume(bus: StringName, percent: int) -> void:
	volumes[bus] = clampi(percent, 0, 100)
	_apply(bus)
	var values := {}
	for name in BUSES:
		values[String(name)] = volumes[name]
	SettingsFile.save_section(SECTION, values)
	changed.emit()


func _apply(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("AudioSettings: no audio bus named %s" % bus)
		return
	var percent: int = volumes[bus]
	AudioServer.set_bus_volume_linear(index, percent / 100.0)
	AudioServer.set_bus_mute(index, percent == 0)
