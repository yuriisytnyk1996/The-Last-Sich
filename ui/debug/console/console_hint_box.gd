class_name ConsoleHintBox
extends PanelContainer
## The hint list hanging under the debug console's command line (what it
## lists comes from `ConsoleHints`). Commands and values can be picked
## with the keyboard: `move()` walks a highlight over them, skipping the
## usage lines, and `selected_pick()` is the word to put in the line.

const TEXT_COLOR := Color(0.7, 0.72, 0.78)
const SELECTED_COLOR := Color(1.0, 0.92, 0.7)
const SELECTED_BACKGROUND := Color(0.95, 0.78, 0.45, 0.3)

var _label := RichTextLabel.new()
var _entries: Array[Dictionary] = []
## Index into `_entries`, or -1 while nothing is highlighted.
var _selected := -1


func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ConsoleView.BACKGROUND
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(PRESET_BOTTOM_WIDE)
	grow_vertical = GROW_DIRECTION_END
	mouse_filter = MOUSE_FILTER_IGNORE
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("default_color", TEXT_COLOR)
	add_child(_label)
	hide()


func set_font(font: Font, font_size: int) -> void:
	_label.add_theme_font_override("normal_font", font)
	_label.add_theme_font_size_override("normal_font_size", font_size)


## Lists `entries` (see `ConsoleHints.for_line()`) with nothing
## highlighted; none hides the box.
func show_entries(entries: Array[Dictionary]) -> void:
	_entries = entries
	_selected = -1
	_redraw()
	visible = not entries.is_empty()


## Shown, with at least one entry that can be picked.
func has_picks() -> bool:
	return visible and not _pick_indices().is_empty()


## Moves the highlight to the next (1) or previous (-1) pickable entry,
## wrapping around. From nothing, down starts at the top, up at the bottom.
func move(direction: int) -> void:
	var picks := _pick_indices()
	if picks.is_empty():
		return
	var at := picks.find(_selected)
	if at == -1:
		at = 0 if direction > 0 else picks.size() - 1
	else:
		at = wrapi(at + direction, 0, picks.size())
	_selected = picks[at]
	_redraw()


## The highlighted entry's word, or "" when nothing is highlighted.
func selected_pick() -> String:
	return str(_entries[_selected].pick) if visible and _selected >= 0 else ""


## Hides the box until the text changes. False if it was already hidden.
func dismiss() -> bool:
	if not visible:
		return false
	hide()
	_selected = -1
	return true


func _pick_indices() -> Array[int]:
	var picks: Array[int] = []
	for i in _entries.size():
		if str(_entries[i].pick) != "":
			picks.append(i)
	return picks


func _redraw() -> void:
	var lines := PackedStringArray()
	for i in _entries.size():
		var text := str(_entries[i].text).replace("[", "[lb]")
		if i == _selected:
			text = (
				"[bgcolor=#%s][color=#%s]%s[/color][/bgcolor]"
				% [SELECTED_BACKGROUND.to_html(), SELECTED_COLOR.to_html(false), text]
			)
		lines.append(text)
	_label.text = "\n".join(lines)
