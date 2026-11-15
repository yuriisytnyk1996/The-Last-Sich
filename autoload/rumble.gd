extends Node
## Gamepad vibration (autoload "Rumble").
##
## `play()` vibrates every connected gamepad, unless the player turned
## rumble off in the accessibility options. Requests don't stack: the
## newest one replaces whatever is running.


## `strength` is 0 to 1. Above 0.5 the heavy motor joins in.
func play(strength: float, duration: float) -> void:
	if not AccessibilitySettings.rumble or strength <= 0.0 or duration <= 0.0:
		return
	strength = clampf(strength, 0.0, 1.0)
	var weak := strength
	var strong := clampf(strength * 2.0 - 1.0, 0.0, 1.0)
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)


func stop() -> void:
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)
