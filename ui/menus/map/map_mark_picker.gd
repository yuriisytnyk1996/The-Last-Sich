class_name MapMarkPicker
extends Control
## The row of player mark kinds shown at the bottom of the `MapView` while
## a mark is being placed: every `PlayerMarks.Kind` in a slot, a frame on
## the chosen one and its name above the row. `MapView` passes it input
## while it is open: left and right choose, attack or accept places, back
## cancels.

## The player picked `kind`. The picker has closed.
signal chosen(kind: PlayerMarks.Kind)
## The player backed out. The picker has closed.
signal cancelled

const SLOT := 11.0
const FRAME_COLOR := Color(0.95, 0.8, 0.35)
const PANEL_COLOR := Color(0.1, 0.09, 0.13, 0.95)
const TEXT_COLOR := Color(0.92, 0.88, 0.76)
const FONT_SIZE := 8

var choice := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func open() -> void:
	show()
	queue_redraw()


## Handles `event` while open. Returns false for input it doesn't use.
func handle_input(event: InputEvent) -> bool:
	if event.is_action_pressed(&"move_left") or event.is_action_pressed(&"ui_left"):
		_step(-1)
	elif event.is_action_pressed(&"move_right") or event.is_action_pressed(&"ui_right"):
		_step(1)
	elif event.is_action_pressed(&"attack") or event.is_action_pressed(&"ui_accept"):
		hide()
		chosen.emit(choice as PlayerMarks.Kind)
	elif event.is_action_pressed(&"ui_cancel"):
		hide()
		cancelled.emit()
	else:
		return false
	return true


## Moves the choice by `by`, wrapping around the row.
func _step(by: int) -> void:
	choice = wrapi(choice + by, 0, PlayerMarks.Kind.size())
	queue_redraw()


func _draw() -> void:
	var count := PlayerMarks.Kind.size()
	var row := Rect2(
		Vector2((size.x - SLOT * count) * 0.5, size.y - SLOT - 4.0), Vector2(SLOT * count, SLOT)
	)
	row = Rect2(row.position.floor(), row.size)
	draw_rect(row.grow(2.0), PANEL_COLOR)
	for i in count:
		var slot := Rect2(row.position + Vector2(SLOT * i, 0), Vector2(SLOT, SLOT))
		MapMarkPainter.draw_mark(self, i, slot.get_center())
		if i == choice:
			draw_rect(slot, FRAME_COLOR, false, 1.0)
	var font := get_theme_default_font()
	var name_text := PlayerMarks.kind_name(choice as PlayerMarks.Kind)
	var width := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var spot := Vector2(floorf((size.x - width) * 0.5), row.position.y - 4.0)
	draw_string(font, spot, name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
