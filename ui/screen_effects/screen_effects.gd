class_name ScreenEffects
extends CanvasLayer
## Full-screen pass over everything, menus included: the brightness
## option and the CRT filter. Owned by `DisplaySettings`.
##
## It reads the finished frame and draws it back with
## `screen_effects.gdshader`. When brightness is 100% and the CRT filter
## is off it hides itself, so the default costs nothing.

## The CRT presets in menu order. Index -1 means the filter is off.
const CRT_PRESETS: Array[CrtPreset] = [
	preload("res://ui/screen_effects/crt_presets/soft_crt.tres"),
	preload("res://ui/screen_effects/crt_presets/living_room_tv.tres"),
	preload("res://ui/screen_effects/crt_presets/small_crt.tres"),
	preload("res://ui/screen_effects/crt_presets/colour_tv.tres"),
	preload("res://ui/screen_effects/crt_presets/old_tv.tres"),
	preload("res://ui/screen_effects/crt_presets/sharp_monitor.tres"),
	preload("res://ui/screen_effects/crt_presets/arcade.tres"),
	preload("res://ui/screen_effects/crt_presets/broken_black_and_white.tres"),
	preload("res://ui/screen_effects/crt_presets/green_terminal.tres"),
	preload("res://ui/screen_effects/crt_presets/amber_terminal.tres"),
]
const SHADER := preload("res://ui/screen_effects/screen_effects.gdshader")

var _material := ShaderMaterial.new()
var _rect := ColorRect.new()
var _gamma := 1.0
var _crt := -1


func _init() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material.shader = SHADER
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	_refresh()


## `gamma` 1 leaves the picture as it is. Above 1 lifts dark areas.
func set_gamma(gamma: float) -> void:
	_gamma = gamma
	_material.set_shader_parameter("gamma", gamma)
	_refresh()


## Index into `CRT_PRESETS`, or -1 to turn the filter off.
func set_crt(index: int) -> void:
	_crt = index if index >= 0 and index < CRT_PRESETS.size() else -1
	_material.set_shader_parameter("crt", _crt >= 0)
	if _crt >= 0:
		CRT_PRESETS[_crt].apply_to(_material)
	_refresh()


func _refresh() -> void:
	visible = _crt >= 0 or not is_equal_approx(_gamma, 1.0)
