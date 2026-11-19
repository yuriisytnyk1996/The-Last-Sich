class_name ConsoleView
extends Control
## The debug console's panel along the top of the screen: a fixed box of
## `LINES_SHOWN` output lines that scrolls, the command line below, and
## under it a hint list that drops over the game while something is typed
## (see `ConsoleHints`). Built in code; debug text is never translated.
## Drawn at the screen's own resolution (see `ConsoleBackdrop`) in a
## monospace system font, so columns line up.

signal submitted(line: String)
signal completion_requested
## The command line's text changed, by typing, Tab or history.
signal line_changed(line: String)

const MAX_LINES := 200
## Output lines the box shows; older ones scroll up.
const LINES_SHOWN := 17
## The text size is the window height divided by this: 22 px at 1080p.
const LINES_PER_SCREEN := 48
const MIN_FONT_SIZE := 12
const FONTS: PackedStringArray = ["Menlo", "Consolas", "DejaVu Sans Mono", "monospace"]
const BACKGROUND := Color(0.02, 0.02, 0.03, 0.88)
const ECHO_COLOR := Color(0.95, 0.78, 0.45)
const HINT_COLOR := Color(0.7, 0.72, 0.78)

var input := ConsoleInput.new()
var _output := RichTextLabel.new()
var _margin := MarginContainer.new()
var _font := SystemFont.new()
var _hints := Label.new()
var _hint_box := PanelContainer.new()


func _init() -> void:
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	set_anchors_preset(PRESET_TOP_WIDE)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(PRESET_FULL_RECT)
	add_child(background)
	_margin.set_anchors_preset(PRESET_FULL_RECT)
	add_child(_margin)
	var column := VBoxContainer.new()
	_margin.add_child(column)
	_font.font_names = FONTS
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.focus_mode = FOCUS_NONE
	_output.size_flags_vertical = SIZE_EXPAND_FILL
	_output.add_theme_font_override("normal_font", _font)
	column.add_child(_output)
	input.placeholder_text = "Type help and press Enter. Tab completes, F1 or Esc closes."
	input.add_theme_font_override("font", _font)
	input.text_submitted.connect(_on_text_submitted)
	input.completion_requested.connect(completion_requested.emit)
	input.scroll_requested.connect(_scroll)
	# Nothing else may take the keys while the console is open.
	input.focus_exited.connect(_keep_focus)
	input.text_changed.connect(line_changed.emit)
	column.add_child(input)
	_build_hint_box()


## Keys the command line leaves alone stop here, so none reaches the
## game or an open menu behind the console.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		accept_event()


## Shows the panel with text sized for a window `window_height` px tall,
## the box `LINES_SHOWN` lines high (never taller than the window).
func open(window_height: int) -> void:
	var font_size := maxi(window_height / LINES_PER_SCREEN, MIN_FONT_SIZE)
	_output.add_theme_font_size_override("normal_font_size", font_size)
	input.add_theme_font_size_override("font_size", font_size)
	_hints.add_theme_font_size_override("font_size", font_size)
	var margin := font_size / 2
	for side: String in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, margin)
	var lines := ceilf(_font.get_height(font_size)) * LINES_SHOWN
	var height := lines + input.get_combined_minimum_size().y + margin * 3
	offset_bottom = minf(height, window_height)
	show()
	input.take_focus()
	_to_bottom()


func close() -> void:
	hide()
	show_hints([])
	input.clear()
	input.release_focus()


## Shows `lines` under the command line; none hides the list.
func show_hints(lines: PackedStringArray) -> void:
	_hints.text = "\n".join(lines)
	_hint_box.visible = not lines.is_empty()


func write(text: String, color := ConsoleShell.TEXT_COLOR) -> void:
	if _output.get_paragraph_count() > MAX_LINES:
		_output.remove_paragraph(0)
	_output.push_color(color)
	_output.add_text(text + "\n")
	_output.pop()
	_to_bottom.call_deferred()


func clear() -> void:
	_output.clear()


## Hangs below the panel's bottom edge, as wide as the panel, as tall as
## its lines.
func _build_hint_box() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.set_content_margin_all(6)
	_hint_box.add_theme_stylebox_override("panel", style)
	_hint_box.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_hint_box.grow_vertical = GROW_DIRECTION_END
	_hint_box.mouse_filter = MOUSE_FILTER_IGNORE
	_hint_box.hide()
	_hints.add_theme_font_override("font", _font)
	_hints.add_theme_color_override("font_color", HINT_COLOR)
	_hint_box.add_child(_hints)
	add_child(_hint_box)


func _keep_focus() -> void:
	if visible:
		input.take_focus.call_deferred()


## Half a box up (-1) or down (1).
func _scroll(direction: int) -> void:
	var bar := _output.get_v_scroll_bar()
	bar.value += direction * bar.page / 2.0


## Every new line shows the end of the output, even after scrolling up.
func _to_bottom() -> void:
	var bar := _output.get_v_scroll_bar()
	bar.value = bar.max_value


func _on_text_submitted(line: String) -> void:
	input.clear()
	show_hints([])
	if line.strip_edges().is_empty():
		return
	input.remember(line)
	write("> " + line, ECHO_COLOR)
	submitted.emit(line)
