class_name ResolutionList
extends RefCounted
## Window resolutions the player can pick in the video options.
##
## Godot can't list a monitor's display modes, so the list is the common
## 16:9 and 16:10 sizes that fit on the current screen, plus the screen's
## own size. Nothing smaller than the 640×360 base resolution is offered.

const BASE := Vector2i(640, 360)
const COMMON: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1024, 576),
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1440),
	Vector2i(2560, 1600),
	Vector2i(3200, 1800),
	Vector2i(3840, 2160),
]


## Sizes that fit the screen the window is on, smallest first.
static func available() -> Array[Vector2i]:
	var screen := screen_size()
	var sizes: Array[Vector2i] = []
	for size in COMMON:
		if size.x <= screen.x and size.y <= screen.y:
			sizes.append(size)
	if not screen in sizes and screen.x >= BASE.x and screen.y >= BASE.y:
		sizes.append(screen)
	sizes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x * a.y < b.x * b.y)
	return sizes


static func screen_size() -> Vector2i:
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


## True when `size` is not a whole multiple of the base resolution, so the
## pixel-perfect and fill scaling modes give different pictures.
static func needs_scaling_choice(size: Vector2i) -> bool:
	var scale := minf(float(size.x) / BASE.x, float(size.y) / BASE.y)
	return not is_equal_approx(scale, floorf(scale))


static func describe(size: Vector2i) -> String:
	return "%d×%d" % [size.x, size.y]
