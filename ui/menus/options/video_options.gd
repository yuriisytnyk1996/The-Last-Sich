class_name VideoOptions
extends MenuScreen
## Video options, all stored in `DisplaySettings`.
##
## Window rows are hidden on phones. Resolution only applies in windowed
## mode, and the scaling row only shows when the picture is not an exact
## multiple of 640×360, because otherwise both modes look the same.

const SCALING: PackedStringArray = ["Pixel perfect", "Fill screen"]
const TEXTURES: PackedStringArray = ["Sharp", "Smooth"]
const BRIGHTNESS_STEP := 10

var _resolutions: Array[Vector2i] = []
var _fullscreen: OptionRow
var _resolution: OptionRow
var _scaling: OptionRow


func _build() -> void:
	var settings := DisplaySettings
	add_title("Video")
	_fullscreen = add_option("Fullscreen", ON_OFF, int(settings.fullscreen), _on_fullscreen)
	_resolution = add_option("Resolution", [], 0, _on_resolution)
	_scaling = add_option("Scaling", SCALING, settings.scaling_mode, settings.set_scaling_mode)
	add_option(
		"VSync", ON_OFF, int(settings.vsync), func(i: int) -> void: settings.set_vsync(i == 1)
	)
	add_option(
		"Textures",
		TEXTURES,
		int(settings.smooth_textures),
		func(i: int) -> void: settings.set_smooth_textures(i == 1)
	)
	add_option("Brightness", _brightness_values(), _brightness_index(), _on_brightness, false)
	add_option(
		"CRT filter",
		_crt_names(),
		settings.crt_preset + 1,
		func(i: int) -> void: settings.set_crt_preset(i - 1)
	)
	add_gap()
	add_button("Back", go_back)
	_fullscreen.visible = not OS.has_feature("mobile")
	settings.changed.connect(_sync)
	_sync()


## Keeps the rows in step with the settings, e.g. after F11.
func _sync() -> void:
	var settings := DisplaySettings
	_fullscreen.set_index(int(settings.fullscreen))
	_resolutions = ResolutionList.available()
	if not settings.resolution in _resolutions:
		_resolutions.append(settings.resolution)
	var names := PackedStringArray()
	for size in _resolutions:
		names.append(ResolutionList.describe(size))
	_resolution.set_values(names, _resolutions.find(settings.resolution))
	_resolution.visible = not settings.fullscreen and not OS.has_feature("mobile")
	_scaling.set_index(settings.scaling_mode)
	_scaling.visible = ResolutionList.needs_scaling_choice(settings.output_size())


func _on_fullscreen(index: int) -> void:
	DisplaySettings.set_fullscreen(index == 1)


func _on_resolution(index: int) -> void:
	DisplaySettings.set_resolution(_resolutions[index])


func _on_brightness(index: int) -> void:
	DisplaySettings.set_brightness(DisplaySettings.MIN_BRIGHTNESS + index * BRIGHTNESS_STEP)


func _brightness_values() -> PackedStringArray:
	return percent_values(
		DisplaySettings.MIN_BRIGHTNESS, DisplaySettings.MAX_BRIGHTNESS, BRIGHTNESS_STEP
	)


func _brightness_index() -> int:
	return roundi(
		float(DisplaySettings.brightness - DisplaySettings.MIN_BRIGHTNESS) / BRIGHTNESS_STEP
	)


func _crt_names() -> PackedStringArray:
	var names: PackedStringArray = ["Off"]
	for preset in ScreenEffects.CRT_PRESETS:
		names.append(preset.display_name)
	return names
