extends Node
## Display options (autoload "DisplaySettings"), changed from the video
## options and saved in the `[display]` section of `user://settings.cfg`.
##
## The game always renders at 640×360 and is scaled up to the window.
## - Fullscreen uses the desktop resolution. Windowed uses `resolution`.
## - Scaling mode decides what happens when the window is not an exact
##   multiple of 640×360: PIXEL_PERFECT scales by whole numbers and leaves
##   black bars, SCALE fills the window with uneven pixels.
## - Brightness and the CRT filter are drawn by `ScreenEffects`.
## F11 / Alt+Enter ("toggle_fullscreen") switch fullscreen in every build.

signal changed

enum ScalingMode { PIXEL_PERFECT, SCALE }

const SECTION := "display"
const MIN_BRIGHTNESS := 50
const MAX_BRIGHTNESS := 150

var fullscreen := true
## Window size when not fullscreen.
var resolution := Vector2i(1280, 720)
var scaling_mode := ScalingMode.PIXEL_PERFECT
var vsync := true
## Linear filtering for scaled or rotated sprites. Off keeps pixels sharp.
var smooth_textures := false
## Percent. 100 leaves the picture untouched.
var brightness := 100
## Index into `ScreenEffects.CRT_PRESETS`, -1 for off.
var crt_preset := -1

var _effects := ScreenEffects.new()


func _ready() -> void:
	add_child(_effects)
	_load()
	_apply_picture()
	_apply_window()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		# Read the real window state: the OS (e.g. the macOS green button)
		# can change it behind our back.
		set_fullscreen(not _is_window_fullscreen())
		get_viewport().set_input_as_handled()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_window()
	_commit()


func set_resolution(size: Vector2i) -> void:
	resolution = size
	_apply_window()
	_commit()


func set_scaling_mode(mode: ScalingMode) -> void:
	scaling_mode = mode
	_apply_picture()
	_commit()


func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_picture()
	_commit()


func set_smooth_textures(enabled: bool) -> void:
	smooth_textures = enabled
	_apply_picture()
	_commit()


func set_brightness(percent: int) -> void:
	brightness = clampi(percent, MIN_BRIGHTNESS, MAX_BRIGHTNESS)
	_apply_picture()
	_commit()


func set_crt_preset(index: int) -> void:
	crt_preset = index
	_apply_picture()
	_commit()


## The size the picture is scaled to: the screen in fullscreen, otherwise
## the window.
func output_size() -> Vector2i:
	if fullscreen:
		return ResolutionList.screen_size()
	return resolution


## Everything except the window mode and size.
func _apply_picture() -> void:
	var root := get_tree().root
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	if scaling_mode == ScalingMode.SCALE:
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	root.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
		if smooth_textures
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)
	var vsync_mode := DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)
	_effects.set_gamma(brightness / 100.0)
	_effects.set_crt(crt_preset)


func _apply_window() -> void:
	# Phones are always fullscreen. In the editor's embedded Game view the
	# editor owns the window, so leave it alone there too.
	if OS.has_feature("mobile") or Engine.is_embedded_in_editor():
		return
	if fullscreen:
		if not _is_window_fullscreen():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen := DisplayServer.window_get_current_screen()
	var area := DisplayServer.screen_get_usable_rect(screen)
	var size := resolution.min(area.size)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(area.position + (area.size - size) / 2)


func _is_window_fullscreen() -> bool:
	if Engine.is_embedded_in_editor():
		return fullscreen
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _commit() -> void:
	_save()
	changed.emit()


func _load() -> void:
	var saved := SettingsFile.load_section(SECTION)
	fullscreen = saved.get("fullscreen", fullscreen) == true
	var size: Variant = saved.get("resolution", resolution)
	if size is Vector2i and size.x >= ResolutionList.BASE.x and size.y >= ResolutionList.BASE.y:
		resolution = size
	var mode: Variant = saved.get("scaling_mode", scaling_mode)
	if mode is int and ScalingMode.values().has(mode):
		scaling_mode = mode as ScalingMode
	vsync = saved.get("vsync", vsync) == true
	smooth_textures = saved.get("smooth_textures", smooth_textures) == true
	brightness = clampi(int(saved.get("brightness", brightness)), MIN_BRIGHTNESS, MAX_BRIGHTNESS)
	crt_preset = int(saved.get("crt_preset", crt_preset))


func _save() -> void:
	(
		SettingsFile
		. save_section(
			SECTION,
			{
				"fullscreen": fullscreen,
				"resolution": resolution,
				"scaling_mode": scaling_mode,
				"vsync": vsync,
				"smooth_textures": smooth_textures,
				"brightness": brightness,
				"crt_preset": crt_preset,
			}
		)
	)
