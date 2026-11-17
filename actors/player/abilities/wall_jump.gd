class_name PlayerWallJump
extends Node
## Finds walls to cling to and holds the wall jump tuning. The WallCling
## and WallJump states do the clinging and the kick off.
##
## Only walls marked with a `ClimbWall` can be climbed, so level design
## decides where the move works. In the air, inside a climb wall, holding
## attack while facing a solid wall right in front of the body drives the
## blade in and grabs it. It is a basic move: no item or skill needed.
## Climb walls add and remove themselves as the player enters and leaves.

## Physics layer of solid ground and walls.
const WORLD_LAYER := 1

@export_group("Cling")
## How far in front of the body a wall is still grabbed (px).
@export var reach := 4.0
## Height above the feet of the lower wall probe (px). The upper one is
## the middle of the body, so a wall beside either the legs or the chest
## can be grabbed.
@export var low_probe_height := 4.0
## Down pushed this far lets go (0 to 1).
@export_range(0.0, 1.0) var let_go_threshold := 0.5
## After grabbing, the player slides this far down before holding still (px).
@export var slide_distance := 8.0
## Time the slide takes (s). It eases out.
@export var slide_time := 0.3
## After letting go or kicking off, no wall can be grabbed for this long (s).
@export var regrab_delay := 0.2

@export_group("Kick")
## Sideways nudge away from the wall when kicking off (px/s). The rise is
## a normal jump and the input steers the rest, so holding away crosses a
## shaft and holding toward the wall comes straight back to grab it higher.
@export var kick_push := 30.0

## The player's body shape, to know where its sides are.
@export var body: CollisionShape2D

## +1 if the grabbed wall is to the right of the player, -1 to the left.
## Set by `wants_grab()`.
var side := 1
## The x of the grabbed wall's face.
var wall_x := 0.0

var _walls: Array[ClimbWall] = []
var _regrab_timer := 0.0

@onready var player := owner as Player


func _physics_process(delta: float) -> void:
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)


func enter(wall: ClimbWall) -> void:
	if not _walls.has(wall):
		_walls.append(wall)


func exit(wall: ClimbWall) -> void:
	_walls.erase(wall)


## In the air, in a climb wall, attack held, facing a wall in front of
## the chest or the legs. Not with down held, which is the dive.
func wants_grab() -> bool:
	if _regrab_timer > 0.0 or player.is_on_floor() or not Input.is_action_pressed("attack"):
		return false
	if player.get_vertical_axis() >= let_go_threshold or not _can_climb():
		return false
	return _find_wall(player.facing)


## The grabbed wall is still beside the body, or would be after moving
## by `offset`. False past its bottom or out of the climb wall.
func is_holding(offset := Vector2.ZERO) -> bool:
	return _can_climb() and _find_wall(side, offset)


## Where the feet go while clinging: the body's side against the wall.
func cling_x() -> float:
	return wall_x - side * _half_width()


func let_go() -> void:
	_regrab_timer = regrab_delay


func _can_climb() -> bool:
	for i in range(_walls.size() - 1, -1, -1):
		if not is_instance_valid(_walls[i]) or not _walls[i].is_inside_tree():
			_walls.remove_at(i)
	return not _walls.is_empty()


func _find_wall(direction: int, offset := Vector2.ZERO) -> bool:
	var low := player.global_position + Vector2(0.0, -low_probe_height)
	for from: Vector2 in [body.global_position, low]:
		var hit := _probe(from + offset, direction)
		if not hit.is_empty():
			side = direction
			wall_x = hit.position.x
			return true
	return false


## A wall face hit by a ray from `from` toward `direction`, or empty.
func _probe(from: Vector2, direction: int) -> Dictionary:
	var to := from + Vector2(direction * (_half_width() + reach), 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 1 << (WORLD_LAYER - 1))
	query.exclude = [player.get_rid()]
	var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.x * direction > -0.5:
		return {}
	return hit


func _half_width() -> float:
	return (body.shape as RectangleShape2D).size.x / 2.0
