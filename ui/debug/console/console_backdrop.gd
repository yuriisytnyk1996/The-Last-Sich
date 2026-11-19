class_name ConsoleBackdrop
extends Control
## Lets the debug console draw its text at the screen's own resolution
## instead of the game's 640×360. `freeze()` takes a picture of the last
## frame, turns the window's content scaling off (the window then renders
## at native size), and shows the picture scaled the way the game was,
## so nothing seems to move. `thaw()` puts the scaling back.
##
## The game is paused while the console is open, so a still picture is all
## it would show anyway. Changes made by commands appear on closing.

var _picture := TextureRect.new()
var _frame_size := Vector2.ZERO
var _scale_mode := Window.CONTENT_SCALE_MODE_VIEWPORT
var _frozen := false


func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(PRESET_FULL_RECT)
	black.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(black)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_picture)
	resized.connect(_place_picture)


func freeze() -> void:
	# Headless runs have no frame to read: stay at the game's resolution.
	if _frozen or DisplayServer.get_name() == "headless":
		return
	var root := get_tree().root
	var frame := root.get_texture().get_image()
	if frame == null or frame.is_empty():
		return
	_picture.texture = ImageTexture.create_from_image(frame)
	_frame_size = Vector2(frame.get_size())
	_scale_mode = root.content_scale_mode
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_frozen = true
	show()
	_place_picture()


func thaw() -> void:
	if not _frozen:
		return
	get_tree().root.content_scale_mode = _scale_mode
	_picture.texture = null
	_frozen = false
	hide()


## Where the game drew its frame in the window: scaled by a whole number
## with integer stretch, as large as fits otherwise, centred.
func _place_picture() -> void:
	if not _frozen or _frame_size == Vector2.ZERO:
		return
	var window := Vector2(get_tree().root.size)
	var factor := minf(window.x / _frame_size.x, window.y / _frame_size.y)
	if get_tree().root.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER:
		factor = maxf(floorf(factor), 1.0)
	_picture.size = _frame_size * factor
	_picture.position = ((window - _picture.size) / 2.0).floor()
