@tool
class_name MovingPlatform
extends AnimatableBody2D
## A platform that travels back and forth between where it is placed and
## `travel` px from there, pausing at each end. It carries the player and
## enemies standing on it.
##
## The origin is the top centre of the platform at its start. One-way by
## default (on the `platforms` layer: jump up through it, drop through with
## down + jump); turn `one_way` off for a solid block on the `world` layer.
## The collision shape is built from `size` when the game runs. The editor
## draws the platform, its path and where it ends up.

const WORLD_LAYER := 1
const PLATFORMS_LAYER := 7
const COLOR := Color(0.55, 0.45, 0.32)
const PATH_COLOR := Color(1.0, 1.0, 1.0, 0.35)

@export var size := Vector2(48.0, 8.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()
## Offset of the far end from the start (px).
@export var travel := Vector2(128.0, 0.0):
	set(value):
		travel = value
		queue_redraw()
## Travel speed (px/s). Eased at both ends.
@export var speed := 50.0
## Seconds it waits at each end.
@export var pause_time := 0.6
## Where in its round trip it starts (0 to 1), so platforms side by side
## can move out of step.
@export_range(0.0, 1.0) var phase := 0.0
@export var one_way := true

var _start := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start = position
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLATFORMS_LAYER if one_way else WORLD_LAYER, true)
	add_child(_make_shape())
	_time = phase * _cycle_time()
	position = _start + travel * _progress(_time)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time = fmod(_time + delta, _cycle_time())
	position = _start + travel * _progress(_time)


func _make_shape() -> CollisionShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, size.y / 2.0)
	shape.one_way_collision = one_way
	return shape


func _move_time() -> float:
	return maxf(travel.length() / maxf(speed, 1.0), 0.01)


func _cycle_time() -> float:
	return 2.0 * (_move_time() + pause_time)


## 0 at the start, 1 at the far end, for a time within one round trip.
func _progress(time: float) -> float:
	var move := _move_time()
	if time < pause_time:
		return 0.0
	time -= pause_time
	if time < move:
		return smoothstep(0.0, 1.0, time / move)
	time -= move + pause_time
	if time < 0.0:
		return 1.0
	return 1.0 - smoothstep(0.0, 1.0, time / move)


func _draw() -> void:
	var rect := Rect2(-size.x / 2.0, 0.0, size.x, size.y)
	draw_rect(rect, COLOR)
	if Engine.is_editor_hint():
		draw_dashed_line(Vector2.ZERO, travel, PATH_COLOR, 1.0, 4.0)
		draw_rect(Rect2(rect.position + travel, rect.size), PATH_COLOR, false)
