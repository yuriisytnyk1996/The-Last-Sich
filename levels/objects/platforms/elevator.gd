@tool
class_name Elevator
extends AnimatableBody2D
## A lift between two stops: where it is placed and `travel` px from
## there. Stand on it for `start_delay` and it carries you to the other
## stop, where it waits. It won't start again until the rider has stepped
## off. `ElevatorCall` levers at the stops bring it to the player.
##
## The origin is the top centre at the first stop. Solid, on the `world`
## layer, so it can't be dropped through. Sink each stop into the floor
## (a notch as deep as `size.y`) so the top is level with the ground. The
## position isn't saved: it is back at the first stop when the room loads.

const WORLD_LAYER := 1
const COLOR := Color(0.42, 0.42, 0.48)
const PATH_COLOR := Color(1.0, 1.0, 1.0, 0.35)

@export var size := Vector2(48.0, 8.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()
## Offset of the second stop from the first (px).
@export var travel := Vector2(0.0, 192.0):
	set(value):
		travel = value
		queue_redraw()
@export var speed := 80.0
## Seconds the player stands on it before it starts.
@export var start_delay := 0.4

## 0 at the first stop, 1 at the second.
var _at := 0.0
var _target := 0.0
var _ride_time := 0.0
## Off after arriving, until the rider steps off.
var _armed := true
var _start := Vector2.ZERO


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start = position
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(WORLD_LAYER, true)
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, size.y / 2.0)
	add_child(shape)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_moving():
		_at = move_toward(_at, _target, speed * delta / maxf(travel.length(), 1.0))
		position = _start + travel * _at
		if not is_moving():
			_armed = false
		return
	if not _is_ridden():
		_ride_time = 0.0
		_armed = true
	elif _armed:
		_ride_time += delta
		if _ride_time >= start_delay:
			_target = 1.0 - _target


func is_moving() -> bool:
	return _at != _target


## Sends the elevator to the stop nearest `from` (global position).
func call_to(from: Vector2) -> void:
	var parent := get_parent() as Node2D
	var first := parent.to_global(_start)
	var second := parent.to_global(_start + travel)
	_target = 0.0 if from.distance_to(first) <= from.distance_to(second) else 1.0
	_ride_time = 0.0


## The player stands on top of it.
func _is_ridden() -> bool:
	var body := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if body == null or not body.is_on_floor():
		return false
	for i in body.get_slide_collision_count():
		if body.get_slide_collision(i).get_collider() == self:
			return true
	return false


func _draw() -> void:
	var rect := Rect2(-size.x / 2.0, 0.0, size.x, size.y)
	draw_rect(rect, COLOR)
	if Engine.is_editor_hint():
		draw_dashed_line(Vector2.ZERO, travel, PATH_COLOR, 1.0, 4.0)
		draw_rect(Rect2(rect.position + travel, rect.size), PATH_COLOR, false)
