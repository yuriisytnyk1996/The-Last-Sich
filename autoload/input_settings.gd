extends Node
## Rebindable controls (autoload "InputSettings"), saved in the
## `[controls]` section of `user://settings.cfg`.
##
## Every gameplay action has one key and one gamepad button (see the
## Input docs). Rebinding swaps the key or button in the `InputMap`, so
## gameplay code keeps reading action names. Stick directions on the move
## actions stay fixed. A key or button already used by another action is
## swapped: that action takes over the old one.
##
## The triggers count as buttons: Godot reports them as axes, so they get
## the codes `LEFT_TRIGGER` and `RIGHT_TRIGGER` (past every real button)
## and are bound as a `InputEventJoypadMotion` pulled past the deadzone.

signal changed

const SECTION := "controls"
const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"jump",
	&"attack",
	&"parry",
	&"dash",
	&"heal",
	&"interact",
	&"ranged",
	&"duma",
	&"map",
	&"inventory",
]
## Keys that keep their job: back / pause, fullscreen and the debug keys
## (save reset, unlock all skills).
const RESERVED_KEYS: Array[Key] = [KEY_ESCAPE, KEY_F11, KEY_F8, KEY_F9]
## Start always pauses.
const RESERVED_BUTTONS: Array[int] = [JOY_BUTTON_START]
## Gamepad codes for the triggers, used where a button index would be.
const LEFT_TRIGGER := 100
const RIGHT_TRIGGER := 101
const TRIGGER_AXES: Dictionary[int, JoyAxis] = {
	LEFT_TRIGGER: JOY_AXIS_TRIGGER_LEFT,
	RIGHT_TRIGGER: JOY_AXIS_TRIGGER_RIGHT,
}


func _ready() -> void:
	var saved := SettingsFile.load_section(SECTION)
	for action in ACTIONS:
		var binding: Variant = saved.get(String(action))
		if binding is Array and binding.size() == 2:
			_replace_key(action, int(binding[0]) as Key)
			_replace_button(action, int(binding[1]))


## Physical key bound to `action`, or KEY_NONE.
func get_key(action: StringName) -> Key:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return KEY_NONE


## Gamepad button (or trigger code) bound to `action`, or
## JOY_BUTTON_INVALID.
func get_button(action: StringName) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return event.button_index
		var trigger := trigger_code(event)
		if trigger != JOY_BUTTON_INVALID:
			return trigger
	return JOY_BUTTON_INVALID


## `LEFT_TRIGGER` or `RIGHT_TRIGGER` for a trigger pulled the right way,
## else JOY_BUTTON_INVALID.
static func trigger_code(event: InputEvent) -> int:
	var motion := event as InputEventJoypadMotion
	if motion == null or motion.axis_value <= 0.0:
		return JOY_BUTTON_INVALID
	for code: int in TRIGGER_AXES:
		if TRIGGER_AXES[code] == motion.axis:
			return code
	return JOY_BUTTON_INVALID


func set_key(action: StringName, key: Key) -> void:
	var old := get_key(action)
	if key == old or key in RESERVED_KEYS:
		return
	for other in ACTIONS:
		if other != action and get_key(other) == key:
			_replace_key(other, old)
	_replace_key(action, key)
	_commit()


func set_button(action: StringName, button: int) -> void:
	var old := get_button(action)
	if button == old or button in RESERVED_BUTTONS:
		return
	for other in ACTIONS:
		if other != action and get_button(other) == button:
			_replace_button(other, old)
	_replace_button(action, button)
	_commit()


## Back to the bindings in `project.godot`.
func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
	SettingsFile.erase_section(SECTION)
	changed.emit()


func _replace_key(action: StringName, key: Key) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	if key == KEY_NONE:
		return
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


func _replace_button(action: StringName, button: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or trigger_code(event) != JOY_BUTTON_INVALID:
			InputMap.action_erase_event(action, event)
	if button == JOY_BUTTON_INVALID:
		return
	if TRIGGER_AXES.has(button):
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = TRIGGER_AXES[button]
		motion.axis_value = 1.0
		InputMap.action_add_event(action, motion)
		return
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button as JoyButton
	InputMap.action_add_event(action, event)


func _commit() -> void:
	var values := {}
	for action in ACTIONS:
		values[String(action)] = [get_key(action), get_button(action)]
	SettingsFile.save_section(SECTION, values)
	changed.emit()
