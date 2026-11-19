class_name BindingButton
extends Button
## Shows the key or gamepad button bound to one action. Press it, then
## press the new key (or button, or pull a trigger) to rebind through
## `InputSettings`.
##
## While waiting, every input goes here first. Escape, Start, a click or
## a press on the other device cancels.

enum Device { KEYBOARD, GAMEPAD }

const WIDTH := 76.0
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	# InputSettings.LEFT_TRIGGER and RIGHT_TRIGGER (an autoload can't be
	# read in a constant).
	100: "LT",
	101: "RT",
}

var action: StringName
var device: Device
var _waiting := false


func _init(action_name: StringName, which: Device) -> void:
	action = action_name
	device = which
	custom_minimum_size.x = WIDTH
	clip_text = true


func _ready() -> void:
	InputSettings.changed.connect(_refresh)
	_refresh()


func _pressed() -> void:
	text = tr("Press a key...") if device == Device.KEYBOARD else tr("Press a button...")
	# Start listening on the next frame, so the press that opened this
	# doesn't bind itself.
	await get_tree().process_frame
	_waiting = true


func _input(event: InputEvent) -> void:
	if not _waiting or event is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	var button := event as InputEventJoypadButton
	var trigger := InputSettings.trigger_code(event)
	if key and device == Device.KEYBOARD and key.physical_keycode != KEY_ESCAPE:
		InputSettings.set_key(action, key.physical_keycode)
	elif button and device == Device.GAMEPAD and button.button_index != JOY_BUTTON_START:
		InputSettings.set_button(action, button.button_index)
	elif trigger != JOY_BUTTON_INVALID and device == Device.GAMEPAD:
		InputSettings.set_button(action, trigger)
	elif not (key or button or event is InputEventMouseButton):
		return  # Stick motion and the like: keep waiting.
	_waiting = false
	_refresh()


func _refresh() -> void:
	if device == Device.KEYBOARD:
		text = key_name(InputSettings.get_key(action))
	else:
		text = button_name(InputSettings.get_button(action))


## Name of the key at a physical position on the player's layout.
static func key_name(key: Key) -> String:
	if key == KEY_NONE:
		return "-"
	if DisplayServer.get_name() == "headless":
		return OS.get_keycode_string(key)  # No keyboard layout to ask.
	return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(key))


## Static, so `TranslationServer.tr()` stands in for `tr()`.
static func button_name(button: int) -> String:
	match button:
		JOY_BUTTON_DPAD_UP:
			return TranslationServer.tr("D-pad up")
		JOY_BUTTON_DPAD_DOWN:
			return TranslationServer.tr("D-pad down")
		JOY_BUTTON_DPAD_LEFT:
			return TranslationServer.tr("D-pad left")
		JOY_BUTTON_DPAD_RIGHT:
			return TranslationServer.tr("D-pad right")
		JOY_BUTTON_INVALID:
			return "-"
	return BUTTON_NAMES.get(button, TranslationServer.tr("Button %d") % button)
