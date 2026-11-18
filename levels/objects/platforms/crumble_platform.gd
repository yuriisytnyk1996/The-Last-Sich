@tool
class_name CrumblePlatform
extends StaticBody2D
## A platform that gives way under the player. Once the player stands on
## it, it shakes for `crumble_delay`, then gives way: it drops and fades
## (`falls`, a collapsing bridge) or fades in place (a vanishing
## platform), and the player falls through. After `return_time` it comes
## back, waiting while the player is in its way; with 0 it is gone until
## the room loads again. Not saved.
##
## A row of them makes a collapsing bridge the player has to run across.
## The origin is the top centre. One-way by default (on the `platforms`
## layer, like planks); turn `one_way` off for a solid block on `world`.
## The collision shape is built from `size` when the game runs. Put it in
## the room's `Layout`.

enum Phase { SOLID, SHAKING, GONE }

const WORLD_LAYER := 1
const PLAYER_LAYER := 2
const PLATFORMS_LAYER := 7
const COLOR := Color(0.62, 0.5, 0.36)
const CRACK_COLOR := Color(0.32, 0.25, 0.18)
## How often the shake picks a new offset (s).
const SHAKE_STEP := 0.04

@export var size := Vector2(32.0, 8.0):
	set(value):
		size = value.max(Vector2.ONE)
		queue_redraw()
@export var one_way := true
## Seconds it shakes under the player before giving way.
@export var crumble_delay := 0.5
## Drops while it fades (collapsing); off fades in place (vanishing).
@export var falls := true
## How far it drops while fading (px).
@export var fall_distance := 24.0
## Seconds it takes to fade out, and to fade back in.
@export var vanish_time := 0.3
## Seconds until it comes back. 0: gone until the room loads again.
@export var return_time := 3.0
## Sideways shake while it crumbles (px).
@export var shake_amount := 1.0

var phase := Phase.SOLID

var _shape: CollisionShape2D
var _offset := Vector2.ZERO
var _time_left := 0.0
var _shake_left := 0.0
var _tween: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PLATFORMS_LAYER if one_way else WORLD_LAYER, true)
	_shape = _make_shape()
	add_child(_shape)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if phase == Phase.SOLID and _is_stood_on():
		phase = Phase.SHAKING
		_time_left = crumble_delay
	elif phase == Phase.SHAKING:
		_shake(delta)
		_time_left -= delta
		if _time_left <= 0.0:
			_give_way()


## True if the player landed on top of it in its last move.
func _is_stood_on() -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if player == null or not player.is_on_floor():
		return false
	for i in player.get_slide_collision_count():
		var hit := player.get_slide_collision(i)
		if hit.get_collider() == self and hit.get_normal().y < -0.5:
			return true
	return false


func _shake(delta: float) -> void:
	_shake_left -= delta
	if _shake_left > 0.0:
		return
	_shake_left = SHAKE_STEP
	_offset.x = roundf(randf_range(-shake_amount, shake_amount))
	queue_redraw()


func _give_way() -> void:
	phase = Phase.GONE
	_offset.x = 0.0
	# Deferred: collision can't change during a physics callback.
	_shape.set_deferred(&"disabled", true)
	_restart_tween()
	_tween.tween_property(self, ^"modulate:a", 0.0, vanish_time)
	if falls:
		_tween.parallel().tween_method(_set_drop, 0.0, fall_distance, vanish_time)
	if return_time > 0.0:
		_tween.tween_interval(return_time)
		_tween.tween_callback(_come_back)


func _come_back() -> void:
	if _player_in_the_way():
		get_tree().create_timer(0.2, false).timeout.connect(_come_back)
		return
	_set_drop(0.0)
	_shape.disabled = false
	phase = Phase.SOLID
	_restart_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, vanish_time)


func _player_in_the_way() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape.shape
	query.transform = _shape.global_transform
	query.collision_mask = 1 << (PLAYER_LAYER - 1)
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _set_drop(value: float) -> void:
	_offset.y = value
	queue_redraw()


func _restart_tween() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()


func _make_shape() -> CollisionShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0.0, size.y / 2.0)
	shape.one_way_collision = one_way
	return shape


func _draw() -> void:
	var rect := Rect2(_offset + Vector2(-size.x / 2.0, 0.0), size)
	draw_rect(rect, COLOR)
	# Two cracks mark it apart from a plain plank.
	for x in [-size.x / 4.0, size.x / 5.0]:
		var top := _offset + Vector2(x, 0.0)
		draw_line(top, top + Vector2(2.0, size.y), CRACK_COLOR)
