@tool
class_name TimedPlatform
extends StaticBody2D
## A platform that appears and vanishes on a `PlatformSequence`'s clock.
## `step` says when in the sequence it shows: platforms with the same step
## show together. It blinks before it vanishes, then fades out and the
## player falls through.
##
## Put it under a `PlatformSequence` in the room's `Layout`; on its own it
## stays hidden. The origin is the top centre. One-way by default (on the
## `platforms` layer); turn `one_way` off for a solid block on `world`. A
## solid one doesn't turn solid while the player is inside it. The editor
## draws its step number.

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const PLATFORMS_LAYER := 7
const COLOR := Color(0.42, 0.62, 0.7)
const WARN_COLOR := Color(0.95, 0.95, 1.0)
const STEP_COLOR := Color(1.0, 1.0, 1.0, 0.8)
## Blinks per second while warning.
const BLINK_RATE := 12.0

@export var size := Vector2(32.0, 8.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()
@export var one_way := true
## When in the sequence it shows (0 first). Same step, same time.
@export_range(0, 31) var step := 0:
	set(value):
		step = value
		queue_redraw()

var shown := false

var _shape: CollisionShape2D
var _warning := false
var _blink := false
var _tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(PlayerSafeGround.NO_SAFE_GROUP)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLATFORMS_LAYER if one_way else WORLD_LAYER, true)
	_shape = _make_shape()
	_shape.disabled = true
	add_child(_shape)
	modulate.a = 0.0


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Turns solid once the player is out of the way.
	if shown and _shape.disabled and not _player_in_the_way():
		_shape.set_deferred(&"disabled", false)
	if _warning:
		var blink := fmod(Time.get_ticks_msec() / 1000.0 * BLINK_RATE, 2.0) < 1.0
		if blink != _blink:
			_blink = blink
			queue_redraw()


## Called by the sequence every physics frame.
func set_state(on: bool, warning: bool, fade_time: float) -> void:
	if warning != _warning:
		_warning = warning
		_blink = false
		queue_redraw()
	if on == shown:
		return
	shown = on
	if not on:
		# Deferred: collision can't change during a physics callback.
		_shape.set_deferred(&"disabled", true)
	_fade(1.0 if on else 0.0, fade_time)


func _fade(alpha: float, time: float) -> void:
	if _tween:
		_tween.kill()
	if time <= 0.0:
		modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", alpha, time)


func _player_in_the_way() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = 1 << (PLAYER_LAYER - 1)
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _make_shape() -> CollisionShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, size.y / 2.0)
	shape.one_way_collision = one_way
	return shape


func _draw() -> void:
	var rect := Rect2(-size.x / 2.0, 0.0, size.x, size.y)
	draw_rect(rect, WARN_COLOR if _blink else COLOR)
	if Engine.is_editor_hint():
		var font := ThemeDB.fallback_font
		var at := Vector2(-size.x / 2.0, -2.0)
		draw_string(font, at, str(step), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, STEP_COLOR)
