extends CanvasLayer
## The debug console (autoload "DebugConsole"): F1 in debug builds opens a
## command line over the game for testing: god mode, giving items and
## currency, moving between rooms, setting story flags and more (type
## `help`). Release builds never build it.
##
## The game is paused while it is open, so typing doesn't move the
## player, and it goes back to how it was on closing: a console opened
## over the pause menu leaves the game paused. Its text is drawn at the
## screen's own resolution over a still picture of the game (see
## `ConsoleBackdrop`), above the brightness and CRT pass. The commands
## live in `ui/debug/console/` (see `ConsoleShell`).

const TOGGLE_KEY := KEY_F1

var _shell: ConsoleShell
var _view: ConsoleView
var _backdrop: ConsoleBackdrop
var _was_paused := false


func _init() -> void:
	# Above `ScreenEffects` (128): the picture of the game already has them.
	layer = 129
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if not OS.is_debug_build():
		set_process_input(false)
		return
	_shell = ConsoleShell.new()
	add_child(_shell)
	_backdrop = ConsoleBackdrop.new()
	_backdrop.hide()
	add_child(_backdrop)
	_view = ConsoleView.new()
	_view.hide()
	add_child(_view)
	_shell.printed.connect(_view.write)
	_shell.cleared.connect(_view.clear)
	_shell.close_requested.connect(close)
	_view.submitted.connect(_shell.run_line)
	_view.completion_requested.connect(_on_completion_requested)
	_view.line_changed.connect(_on_line_changed)


func is_open() -> bool:
	return _view != null and _view.visible


func open() -> void:
	if is_open() or _view == null:
		return
	_was_paused = get_tree().paused
	get_tree().paused = true
	_backdrop.freeze()
	_view.open(get_tree().root.size.y)


func close() -> void:
	if not is_open():
		return
	_view.close()
	_backdrop.thaw()
	get_tree().paused = _was_paused


## Before the game and the menus see the event: the toggle key works
## anywhere, and an open console keeps gamepad presses from the menus.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.physical_keycode == TOGGLE_KEY:
			if is_open():
				close()
			else:
				open()
			get_viewport().set_input_as_handled()
		elif is_open() and key.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
	elif is_open() and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		get_viewport().set_input_as_handled()


func _on_completion_requested() -> void:
	_view.input.set_line(_shell.complete(_view.input.text))


func _on_line_changed(line: String) -> void:
	_view.show_hints(ConsoleHints.for_line(_shell, line))
