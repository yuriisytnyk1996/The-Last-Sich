class_name CameraDirector
extends Node
## Lets a cutscene take its parent Camera2D off the player. `pan_to()`
## glides the camera to a point and holds it there, `glide_home()` glides
## it back over the player and `release()` hands it to the player again.
## The room's camera limits still apply: a point near a wall shows the
## room up to that wall, and the glide never runs into the limit.
##
## While directed the camera is `top_level`, so it stops moving with the
## player, and its smoothing is off, so the glide is exactly the tween.

## The camera is away from the player.
var directed := false
var _home := Vector2.ZERO
var _smoothing := false
var _tween: Tween

@onready var camera := get_parent() as Camera2D


func _ready() -> void:
	_home = camera.position
	_smoothing = camera.position_smoothing_enabled


## Glides the view centre to `point` over `duration` seconds.
func pan_to(point: Vector2, duration: float) -> Tween:
	if not directed:
		var start := camera.get_screen_center_position()
		directed = true
		camera.top_level = true
		camera.position_smoothing_enabled = false
		camera.global_position = start
	return _glide(_clamped(point), duration)


## Glides back to where the player's camera would be. Null when the
## camera is already the player's.
func glide_home(duration: float) -> Tween:
	if not directed:
		return null
	var anchor := (camera.get_parent() as Node2D).to_global(_home)
	return _glide(_clamped(anchor), duration)


## Gives the camera back to the player at once.
func release() -> void:
	if _tween:
		_tween.kill()
	if not directed:
		return
	directed = false
	camera.top_level = false
	camera.position = _home
	camera.position_smoothing_enabled = _smoothing
	camera.reset_smoothing()


func _glide(to: Vector2, duration: float) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(camera, ^"global_position", to, maxf(duration, 0.0))
	return _tween


## The closest view centre the room's limits allow.
func _clamped(point: Vector2) -> Vector2:
	var half := camera.get_viewport_rect().size * 0.5 / camera.zoom
	var low := Vector2(camera.limit_left, camera.limit_top) + half
	var high := Vector2(camera.limit_right, camera.limit_bottom) - half
	return Vector2(_fit(point.x, low.x, high.x), _fit(point.y, low.y, high.y))


## A room smaller than the view keeps it centred.
static func _fit(value: float, low: float, high: float) -> float:
	return (low + high) * 0.5 if low > high else clampf(value, low, high)
