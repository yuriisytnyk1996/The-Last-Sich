class_name ScreenFade
extends CanvasLayer
## Full-screen black overlay for room transitions. Runs while the game is
## paused and ignores hit-stop, so a fade always finishes.

## Seconds for one fade, out or in.
@export var duration := 0.15

@onready var rect: ColorRect = $Rect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect.modulate.a = 0.0


func fade_out() -> void:
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	var tween := create_tween().set_ignore_time_scale()
	tween.tween_property(rect, "modulate:a", alpha, duration)
	await tween.finished
