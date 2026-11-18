class_name ScreenFade
extends CanvasLayer
## Full-screen black overlay for room transitions and cutscenes. Runs
## while the game is paused and ignores hit-stop, so a fade always
## finishes. A new fade stops the one still running.

## The world's fade is in this group, so a cutscene can find it.
const GROUP := &"screen_fade"

## Seconds for one fade, out or in, unless a fade asks for its own time.
@export var duration := 0.15

var _tween: Tween

@onready var rect: ColorRect = $Rect


func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect.modulate.a = 0.0


## `time` below 0 uses `duration`.
func fade_out(time := -1.0) -> void:
	await fade_to(1.0, time).finished


func fade_in(time := -1.0) -> void:
	await fade_to(0.0, time).finished


## Fades to `alpha` (1 is black) and returns the running tween.
func fade_to(alpha: float, time := -1.0) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_ignore_time_scale()
	_tween.tween_property(rect, ^"modulate:a", alpha, duration if time < 0.0 else time)
	return _tween
