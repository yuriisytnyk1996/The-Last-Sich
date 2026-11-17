class_name KneelScreen
extends MenuScreen
## The prompt shown while the player kneels at a rest point, once they can
## travel between rest points (`PlayerUnlocks.REST_TRAVEL`). A small panel
## at the bottom of the screen over the paused game, no tint.
##
## `map` opens the map in travel mode (`MapScreen`); back (ui_cancel) or
## interact closes the menu and the player rises.
##
## The prompt names the real keys: the bound `map` key and Escape, or the
## bound `map` button and B, for whichever device was used last.

const PROMPT := "%s: travel    %s: rise"
const PANEL_COLOR := Color(0.1, 0.09, 0.13, 0.9)
const BORDER_COLOR := Color(0.45, 0.4, 0.3)
## Space kept below the panel (px).
const BOTTOM_MARGIN := 24.0

var _map: WorldMap
var _label := Label.new()


func _init(map: WorldMap) -> void:
	_map = map
	backdrop = false


func _build() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	custom_minimum_size.y = 360.0 - BOTTOM_MARGIN * 2.0
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = BORDER_COLOR
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(_label)
	add_child(panel)
	_show_keys(not Input.get_connected_joypads().is_empty())


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_show_keys(false)
	elif event is InputEventJoypadButton:
		_show_keys(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.5:
		_show_keys(true)


func _show_keys(gamepad: bool) -> void:
	if gamepad:
		var map_button := BindingButton.button_name(InputSettings.get_button(&"map"))
		_label.text = PROMPT % [map_button, BindingButton.button_name(JOY_BUTTON_B)]
	else:
		var map_key := BindingButton.key_name(InputSettings.get_key(&"map"))
		_label.text = PROMPT % [map_key, BindingButton.key_name(KEY_ESCAPE)]


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(&"map"):
		menu.push(MapScreen.new(_map, true))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
		go_back()
		get_viewport().set_input_as_handled()
