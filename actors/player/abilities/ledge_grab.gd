class_name PlayerLedgeGrab
extends Node
## Finds ledges to grab and holds the ledge tuning. The LedgeHang and
## LedgeClimb states do the hanging and climbing.
##
## A ledge is the top corner of a solid wall (the `world` layer, never
## one-way planks) that the player falls past while facing it, with room
## above to stand, and with at least `min_drop` of air under the feet while
## hanging, so low steps that a jump clears are never grabbed. Nothing is
## placed by hand: any wall top in the tiles works. Only terrain tiles
## (`TileMapLayer`) count: gates, crates, cracked walls and moving bodies
## on `world` are never grabbed.

## Physics layers of solid ground and walls, and of one-way platforms.
const WORLD_LAYER := 1
const PLATFORMS_LAYER := 7

## Hands above the feet (px). The ledge top is held at this height.
@export var hand_height := 28.0
## How far in front of the body a wall is still grabbed (px).
@export var grab_reach := 4.0
## How far above or below the hands the ledge top can be and still be
## caught in one frame (px). Covers the distance fallen per frame.
@export var snap_window := 8.0
## Air needed under the feet while hanging (px). Walls shorter than
## `hand_height` + this aren't ledges.
@export var min_drop := 16.0
## Vertical input needed to climb up or drop down (0 to 1).
@export_range(0.0, 1.0) var input_threshold := 0.5
## Hanging this long before up or jump climbs (s), so a held up doesn't
## skip the hang.
@export var climb_delay := 0.1
## Time to pull the body up beside the wall, then to step onto the top (s).
@export var climb_rise_time := 0.15
@export var climb_over_time := 0.08
## After dropping off a ledge, ledges can't be grabbed for this long (s).
@export var regrab_delay := 0.25
## The player's body shape, to check there is room on top of a ledge.
@export var body: CollisionShape2D

## The grabbed ledge's top corner, set by `wants_grab()`.
var corner := Vector2.ZERO
## +1 if the wall is to the right of the player, -1 to the left.
var side := 1

var _regrab_timer := 0.0

@onready var player := owner as Player


func _physics_process(delta: float) -> void:
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)


## Falling past a ledge in front of the player, with down not held.
func wants_grab() -> bool:
	if _regrab_timer > 0.0 or player.velocity.y < 0.0 or player.is_on_floor():
		return false
	if player.get_vertical_axis() >= input_threshold:
		return false
	return _find_ledge(player.facing)


## Where the feet go while hanging.
func hang_position() -> Vector2:
	return Vector2(corner.x - side * _half_width(), corner.y + hand_height)


## Where the feet go once climbed onto the top.
func stand_position() -> Vector2:
	return Vector2(corner.x + side * (_half_width() + 1.0), corner.y)


func let_go() -> void:
	_regrab_timer = regrab_delay


func _find_ledge(direction: int) -> bool:
	var space := player.get_world_2d().direct_space_state
	var hands := player.global_position + Vector2(0.0, -hand_height)
	# A wall in front, just below the hands.
	var wall_from := hands + Vector2(0.0, snap_window)
	var wall_to := wall_from + Vector2(direction * (_half_width() + grab_reach), 0.0)
	var wall := space.intersect_ray(_ray(wall_from, wall_to))
	if wall.is_empty() or wall.normal.x * direction > -0.5 or not _is_terrain(wall):
		return false
	# Its top, within the snap window around the hands.
	var probe_x: float = wall.position.x + direction
	var top_from := Vector2(probe_x, hands.y - snap_window)
	var top_to := Vector2(probe_x, wall_from.y)
	if _is_solid(space, top_from):
		return false  # The wall goes on above the hands: no ledge here.
	var top := space.intersect_ray(_ray(top_from, top_to))
	if top.is_empty() or top.normal.y > -0.5 or not _is_terrain(top):
		return false
	corner = Vector2(wall.position.x, top.position.y)
	side = direction
	return _has_drop_below(space) and _fits_on_top(space)


## Nothing solid (ground or a platform) within `min_drop` under the
## hanging feet.
func _has_drop_below(space: PhysicsDirectSpaceState2D) -> bool:
	var feet := hang_position()
	var query := _ray(feet, feet + Vector2(0.0, min_drop))
	query.collision_mask |= 1 << (PLATFORMS_LAYER - 1)
	return space.intersect_ray(query).is_empty()


## The body has room to stand on the ledge.
func _fits_on_top(space: PhysicsDirectSpaceState2D) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body.shape
	query.transform = Transform2D(0.0, stand_position() + body.position)
	query.transform.origin.y -= 0.5
	query.collision_mask = 1 << (WORLD_LAYER - 1)
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func _is_terrain(hit: Dictionary) -> bool:
	return hit.collider is TileMapLayer


func _is_solid(space: PhysicsDirectSpaceState2D, point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1 << (WORLD_LAYER - 1)
	return not space.intersect_point(query, 1).is_empty()


func _ray(from: Vector2, to: Vector2) -> PhysicsRayQueryParameters2D:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1 << (WORLD_LAYER - 1))
	query.exclude = [player.get_rid()]
	return query


func _half_width() -> float:
	return (body.shape as RectangleShape2D).size.x / 2.0
