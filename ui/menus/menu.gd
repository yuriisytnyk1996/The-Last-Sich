class_name Menu
extends CanvasLayer
## A stack of `MenuScreen`s over a tinted background. The main menu and
## the pause menu are both one of these.
##
## `push()` opens a screen on top, `pop()` goes back one. Back (ui_cancel:
## Escape / B) calls the top screen's `go_back()`. Runs while the game is
## paused. `closed` fires when the last screen is popped.

signal closed

const THEME := preload("res://ui/menus/menu_theme.tres")

## Tint behind the screens.
@export var background := Color(0.03, 0.02, 0.05, 0.8)

var _stack: Array[MenuScreen] = []
var _root := Control.new()
var _tint := ColorRect.new()
var _holder := CenterContainer.new()


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_root.theme = THEME
	_root.visible = false
	for control: Control in [_root, _tint, _holder]:
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.color = background
	_tint.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_tint)
	_root.add_child(_holder)
	add_child(_root)


func is_open() -> bool:
	return not _stack.is_empty()


## The screen on top, or null when closed.
func top_screen() -> MenuScreen:
	return null if _stack.is_empty() else _stack.back()


func push(screen: MenuScreen) -> void:
	if is_open():
		var top := _stack.back() as MenuScreen
		top.remember_focus()
		top.hide()
	screen.menu = self
	_stack.append(screen)
	_holder.add_child(screen)
	_tint.visible = screen.backdrop
	_root.show()
	screen.focus_first()


func pop() -> void:
	if not is_open():
		return
	_discard(_stack.pop_back())
	if not is_open():
		_root.hide()
		closed.emit()
		return
	var top := _stack.back() as MenuScreen
	_tint.visible = top.backdrop
	top.show()
	top.restore_focus()


## Pops every screen at once.
func close() -> void:
	if not is_open():
		return
	while _stack.size() > 1:
		_discard(_stack.pop_back())
	pop()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	var top := _stack.back() as MenuScreen
	if event.is_action_pressed("ui_cancel"):
		Audio.play(&"ui_back")
		top.go_back()
		get_viewport().set_input_as_handled()
	elif _is_navigation(event) and get_viewport().gui_get_focus_owner() == null:
		# Focus is lost after clicking empty space. Arrows bring it back.
		top.focus_first()
		get_viewport().set_input_as_handled()


func _is_navigation(event: InputEvent) -> bool:
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		if event.is_action_pressed(action):
			return true
	return false


func _discard(screen: MenuScreen) -> void:
	_holder.remove_child(screen)
	screen.queue_free()
