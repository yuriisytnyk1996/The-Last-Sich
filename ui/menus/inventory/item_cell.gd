class_name ItemCell
extends Button
## One square of the inventory page: an item in the grid, or a worn slot
## in the row above it. Draws its own frame for each state: empty, holding
## an item, worn, locked (a slot not opened yet), highlighted (the worn
## copy of the item focused in the grid) and focused.

const SIZE := Vector2(24, 24)
const BACK_EMPTY := Color(0.1, 0.09, 0.1)
const BACK_ITEM := Color(0.17, 0.15, 0.15)
const BACK_WORN := Color(0.32, 0.24, 0.12)
const BACK_LOCKED := Color(0.08, 0.06, 0.06)
const FRAME := Color(0.3, 0.27, 0.25)
const FRAME_WORN := Color(0.7, 0.55, 0.3)
const FRAME_FOCUS := Color(1, 0.88, 0.6)
const FRAME_LOCKED := Color(0.24, 0.2, 0.19)
const CROSS := Color(0.42, 0.33, 0.3)

var item: Item:
	set(value):
		item = value
		_icon.item = value
		queue_redraw()
var worn := false:
	set(value):
		worn = value
		queue_redraw()
var locked := false:
	set(value):
		locked = value
		queue_redraw()
var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()

var _icon := ItemIcon.new()


func _init() -> void:
	custom_minimum_size = SIZE
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 3
	_icon.offset_top = 3
	_icon.offset_right = -3
	_icon.offset_bottom = -3
	add_child(_icon)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, _back_color())
	if locked:
		draw_line(Vector2(5, 5), size - Vector2(5, 5), CROSS, 1.0)
		draw_line(Vector2(size.x - 5, 5), Vector2(5, size.y - 5), CROSS, 1.0)
	var frame := FRAME_LOCKED if locked else FRAME
	if has_focus():
		frame = FRAME_FOCUS
	elif worn or highlighted:
		frame = FRAME_WORN
	draw_rect(rect.grow(-0.5), frame, false, 1.0)
	if has_focus():
		# Corner ticks, so the focused cell reads even on a worn one.
		for corner in [
			Vector2.ZERO, Vector2(size.x - 3, 0), Vector2(0, size.y - 3), size - Vector2(3, 3)
		]:
			draw_rect(Rect2(corner, Vector2(3, 3)), FRAME_FOCUS)


func _back_color() -> Color:
	if locked:
		return BACK_LOCKED
	if item == null:
		return BACK_EMPTY
	return BACK_WORN if worn or highlighted else BACK_ITEM
