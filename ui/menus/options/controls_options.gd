class_name ControlsOptions
extends MenuScreen
## Rebinding: one row per action in `InputSettings.ACTIONS`, with a key
## column and a gamepad column.

const LABELS := {
	&"move_left": "Move left",
	&"move_right": "Move right",
	&"move_up": "Up / climb",
	&"move_down": "Down / crouch",
	&"jump": "Jump",
	&"attack": "Attack",
	&"parry": "Parry",
	&"dash": "Dash",
	&"heal": "Heal",
	&"interact": "Interact",
	&"ranged": "Ranged",
}
const NAME_WIDTH := 88.0


func _build() -> void:
	add_title("Controls")
	add_child(_row("", _header("Keyboard"), _header("Gamepad")))
	for action in InputSettings.ACTIONS:
		var key := BindingButton.new(action, BindingButton.Device.KEYBOARD)
		var pad := BindingButton.new(action, BindingButton.Device.GAMEPAD)
		add_child(_row(LABELS.get(action, String(action)), key, pad))
	add_gap()
	add_button("Reset to defaults", _confirm_reset)
	add_button("Back", go_back)


func _confirm_reset() -> void:
	var reset := func() -> void:
		InputSettings.reset_to_defaults()
		menu.pop()
	menu.push(ConfirmScreen.new("Reset all controls to the defaults?", reset))


func _row(title: String, key: Control, pad: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = NAME_WIDTH
	row.add_child(label)
	row.add_child(key)
	row.add_child(pad)
	return row


func _header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"HeaderLabel"
	label.custom_minimum_size.x = BindingButton.WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
