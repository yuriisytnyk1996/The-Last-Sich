extends Node
## Accessibility options (autoload "AccessibilitySettings"), saved in the
## `[accessibility]` section of `user://settings.cfg`.
##
## - `screen_shake`: `CameraShake` ignores shake requests when off.
## - `rumble`: `Rumble` ignores vibration requests when off.
## - `tips`: `TipLog` shows no "how to play" cards when off.

signal changed

const SECTION := "accessibility"

var screen_shake := true
var rumble := true
var tips := true


func _ready() -> void:
	var saved := SettingsFile.load_section(SECTION)
	screen_shake = saved.get("screen_shake", screen_shake) == true
	rumble = saved.get("rumble", rumble) == true
	tips = saved.get("tips", tips) == true


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	_commit()


func set_rumble(enabled: bool) -> void:
	rumble = enabled
	if not enabled:
		Rumble.stop()
	_commit()


func set_tips(enabled: bool) -> void:
	tips = enabled
	_commit()


func _commit() -> void:
	var values := {"screen_shake": screen_shake, "rumble": rumble, "tips": tips}
	SettingsFile.save_section(SECTION, values)
	changed.emit()
