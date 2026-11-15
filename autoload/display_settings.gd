extends Node
## Display options (autoload "DisplaySettings").
##
## The game always renders at 640×360 and is scaled up to the window.
## Scaling mode decides what happens when the window is not an exact
## multiple of 640×360:
## - PIXEL_PERFECT: scale by whole numbers only (sharp, even pixels) and
##   leave black bars around the picture.
## - SCALE: fill the window with a fractional scale (no bars, but some
##   pixels end up one screen pixel wider than others).
## Fullscreen uses the desktop resolution and is on by default.
## Both are saved to user://settings.cfg and restored on start.
## F11 / Alt+Enter ("toggle_fullscreen") switch fullscreen.
## In debug builds, F3 switches scaling mode until an options menu exists.

enum ScalingMode { PIXEL_PERFECT, SCALE }

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "display"

var scaling_mode: ScalingMode = ScalingMode.PIXEL_PERFECT
var fullscreen: bool = true


func _ready() -> void:
	_load()
	apply()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		# Read the real window state: the OS (e.g. the macOS green button)
		# can change it behind our back.
		set_fullscreen(not _is_window_fullscreen())
		get_viewport().set_input_as_handled()
		return
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F3:
		toggle_scaling_mode()
		get_viewport().set_input_as_handled()


func set_scaling_mode(mode: ScalingMode) -> void:
	scaling_mode = mode
	apply()
	_save()


func toggle_scaling_mode() -> void:
	if scaling_mode == ScalingMode.PIXEL_PERFECT:
		set_scaling_mode(ScalingMode.SCALE)
	else:
		set_scaling_mode(ScalingMode.PIXEL_PERFECT)


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply()
	_save()


## Pushes the current settings to the window. Godot re-fits on resize.
func apply() -> void:
	var stretch := Window.CONTENT_SCALE_STRETCH_INTEGER
	if scaling_mode == ScalingMode.SCALE:
		stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	get_tree().root.content_scale_stretch = stretch
	_apply_window_mode()


func _apply_window_mode() -> void:
	# Phones are always fullscreen. In the editor's embedded Game view the
	# editor owns the window, so leave it alone there too.
	if OS.has_feature("mobile") or Engine.is_embedded_in_editor():
		return
	var mode := DisplayServer.WINDOW_MODE_WINDOWED
	if fullscreen:
		mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _is_window_fullscreen() -> bool:
	if Engine.is_embedded_in_editor():
		return fullscreen
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var saved: int = config.get_value(SECTION, "scaling_mode", scaling_mode)
	if ScalingMode.values().has(saved):
		scaling_mode = saved as ScalingMode
	fullscreen = config.get_value(SECTION, "fullscreen", fullscreen) == true


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)  # Keep other sections if the file exists.
	config.set_value(SECTION, "scaling_mode", scaling_mode)
	config.set_value(SECTION, "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)
