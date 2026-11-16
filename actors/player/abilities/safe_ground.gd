class_name PlayerSafeGround
extends Node
## Remembers the last safe spot the player stood on, so what they leave
## behind on death (the dropped currency marker) lands somewhere they can
## walk back to, never in a pit or on spikes.
##
## A spot counts while the player stands or runs on the floor, there is
## ground under both sides (`edge_margin`), no hazard is near
## (`hazard_margin`) and it is away from the room's edges
## (`bounds_margin`). The world calls `enter_room()` on every room load.
## Not saved: after loading, nothing is remembered until the player moves.

## Physics layer mask of hazards (spikes, pits).
const HAZARDS_MASK := 1 << 5

## Distance to each side of the feet that must have ground under it (px).
@export var edge_margin := 12.0
## How far below the feet the ground may be (px).
@export var probe_depth := 4.0
## No hazard within this distance of the feet, sideways (px).
@export var hazard_margin := 24.0
## Distance kept from the room's left and right edges (px).
@export var bounds_margin := 24.0

## Room scene path of the remembered spot, empty while there is none.
var room := ""
## The remembered spot: the player's feet, in global coordinates.
var spot := Vector2.ZERO

var _current_room := ""
var _hazard_query := PhysicsShapeQueryParameters2D.new()

@onready var player := owner as Player


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(hazard_margin * 2.0, 32.0)
	_hazard_query.shape = shape
	_hazard_query.collision_mask = HAZARDS_MASK
	_hazard_query.collide_with_areas = true
	_hazard_query.collide_with_bodies = false


## The player is now in the room at `path`.
func enter_room(path: String) -> void:
	_current_room = path


func _physics_process(_delta: float) -> void:
	if _current_room != "" and _is_safe():
		room = _current_room
		spot = player.global_position


func _is_safe() -> bool:
	var state := player.state_machine.state.name
	if state != PlayerState.IDLE and state != PlayerState.RUN:
		return false
	if not player.is_on_floor() or not _inside_bounds():
		return false
	var feet := player.global_position
	return (
		_has_ground(feet + Vector2.LEFT * edge_margin)
		and _has_ground(feet + Vector2.RIGHT * edge_margin)
		and not _near_hazard(feet)
	)


func _inside_bounds() -> bool:
	var x := player.global_position.x
	var camera := player.camera
	return x >= camera.limit_left + bounds_margin and x <= camera.limit_right - bounds_margin


func _has_ground(at: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		at + Vector2.UP * 2.0, at + Vector2.DOWN * probe_depth, player.collision_mask
	)
	query.exclude = [player.get_rid()]
	return not player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _near_hazard(feet: Vector2) -> bool:
	_hazard_query.transform = Transform2D(0.0, feet + Vector2.UP * 16.0)
	return not player.get_world_2d().direct_space_state.intersect_shape(_hazard_query, 1).is_empty()
