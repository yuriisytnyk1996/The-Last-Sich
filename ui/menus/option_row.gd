class_name OptionRow
extends Button
## A menu row with a name on the left and `< value >` on the right. Left
## and right step through the values, and accept steps forward. A click on
## the left half of the value (the "<" arrow) steps back, anywhere else
## steps forward. Lists and toggles wrap around, ranges such as volume
## stop at the ends.

signal changed(index: int)

const WIDTH := 240.0
## Extra room left of the "<" arrow that still counts as clicking it (px).
const ARROW_SLACK := 8.0

var values: PackedStringArray
var index := 0
var wraps := true

var _value := Label.new()


func _init(title: String, value_names: PackedStringArray, start: int, wrap_around := true) -> void:
	text = title
	values = value_names
	wraps = wrap_around
	index = clampi(start, 0, maxi(values.size() - 1, 0))
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size.x = WIDTH
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_value.offset_right = -6.0
	add_child(_value)
	_refresh()


## Shows a new value without sending `changed`, e.g. when the setting was
## changed somewhere else (F11 toggles fullscreen).
func set_index(new_index: int) -> void:
	index = clampi(new_index, 0, maxi(values.size() - 1, 0))
	_refresh()


func set_values(value_names: PackedStringArray, new_index: int) -> void:
	values = value_names
	set_index(new_index)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT:
		# Handled here instead of `pressed`, which can't tell where the click
		# landed and drops fast repeat clicks (they arrive as double-clicks).
		if click.pressed:
			grab_focus()
			_step(-1 if _is_back_arrow(click.position) else 1)
		accept_event()
	elif event.is_action_pressed("ui_left", true):
		_step(-1)
		accept_event()
	elif event.is_action_pressed("ui_right", true):
		_step(1)
		accept_event()


func _pressed() -> void:
	_step(1)


func _is_back_arrow(point: Vector2) -> bool:
	var font := _value.get_theme_font("font")
	var font_size := _value.get_theme_font_size("font_size")
	var width := font.get_string_size(_value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var start := size.x + _value.offset_right - width
	return point.x >= start - ARROW_SLACK and point.x < start + width / 2.0


func _step(direction: int) -> void:
	if values.is_empty():
		return
	var next := index + direction
	if wraps:
		next = posmod(next, values.size())
	else:
		next = clampi(next, 0, values.size() - 1)
	if next == index:
		return
	index = next
	_refresh()
	changed.emit(index)


func _refresh() -> void:
	_value.text = "< %s >" % values[index] if not values.is_empty() else ""
