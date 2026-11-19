class_name ConsoleInput
extends LineEdit
## The debug console's command line. Up and down step through the lines
## run before, kept in `HISTORY_FILE` across runs. Tab asks for
## completion and PageUp / PageDown scroll the output. It keeps editing
## after Enter, so the next command can be typed at once.

signal completion_requested
## -1 for PageUp, 1 for PageDown.
signal scroll_requested(direction: int)

const HISTORY_FILE := "user://console_history.txt"
const HISTORY_SIZE := 100

var _history: PackedStringArray = []
## Where up and down are in `_history`; its size means a fresh line.
var _index := 0


func _init() -> void:
	keep_editing_on_text_submit = true
	if FileAccess.file_exists(HISTORY_FILE):
		_history = FileAccess.get_file_as_string(HISTORY_FILE).split("\n", false)
	_index = _history.size()


## Runs before the line's own key handling, so these keys never reach it.
func _gui_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_UP:
			_step(-1)
		KEY_DOWN:
			_step(1)
		KEY_TAB:
			completion_requested.emit()
		KEY_PAGEUP:
			scroll_requested.emit(-1)
		KEY_PAGEDOWN:
			scroll_requested.emit(1)
		_:
			return
	accept_event()


## Keeps `line` for up and down, skipping a repeat of the last one.
func remember(line: String) -> void:
	if _history.is_empty() or _history[-1] != line:
		_history.append(line)
		_history = _history.slice(-HISTORY_SIZE)
		var file := FileAccess.open(HISTORY_FILE, FileAccess.WRITE)
		if file:
			file.store_string("\n".join(_history))
	_index = _history.size()


## Takes the keyboard and starts editing, so typing goes in right away.
func take_focus() -> void:
	grab_focus()
	edit()


## Replaces the text as if typed: the hints follow it.
func set_line(line: String) -> void:
	text = line
	caret_column = text.length()
	text_changed.emit(text)


func _step(direction: int) -> void:
	if _history.is_empty():
		return
	_index = clampi(_index + direction, 0, _history.size())
	set_line("" if _index == _history.size() else _history[_index])
