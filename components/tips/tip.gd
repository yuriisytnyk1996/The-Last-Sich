class_name Tip
extends Resource
## One "how to play" card: a title and a short text, shown once the first
## time something happens (see `TipLog`) and kept for rereading in the
## pause menu.
##
## The text may name actions in braces, "{interact}", which are shown as
## the key or button bound to them right now: "[E]", "[Y]". An open card
## switches them when the player changes device (see `device_of()`).

const ACTION_PATTERN := "\\{(\\w+)\\}"
## A stick pushed past this counts as using the gamepad.
const STICK_DEADZONE := 0.5

## Saved once seen. Never rename an id that has shipped.
@export var id := &""
@export var title := ""
@export_multiline var text := ""
## Shown above the text when set: the move being explained.
@export var image: Texture2D
## Listed in Pause > Tips from the start, before it was ever shown.
@export var known_from_start := false


## The text with every "{action}" replaced by its binding on the keyboard,
## or on the gamepad when `gamepad` is set.
func formatted_text(gamepad: bool) -> String:
	var regex := RegEx.create_from_string(ACTION_PATTERN)
	var result := text
	for found in regex.search_all(text):
		var action := StringName(found.get_string(1))
		if InputMap.has_action(action):
			result = result.replace(found.get_string(), "[%s]" % _binding(action, gamepad))
	return result


static func _binding(action: StringName, gamepad: bool) -> String:
	if gamepad:
		return BindingButton.button_name(InputSettings.get_button(action))
	return BindingButton.key_name(InputSettings.get_key(action))


## 1 for a gamepad press or a pushed stick, 0 for a key or a click, -1
## for anything else (mouse motion, a stick at rest).
static func device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return 0
	var motion := event as InputEventJoypadMotion
	if event is InputEventJoypadButton or (motion and absf(motion.axis_value) > STICK_DEADZONE):
		return 1
	return -1
