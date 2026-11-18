class_name PlayerScripted
extends Node
## Hands the player to a cutscene. `take()` puts them in the `Scripted`
## state (no input, can't be hurt), `walk_to()` walks them to a spot and
## `release()` gives control back. The walk itself runs in the state.

## The player reached the spot `walk_to()` asked for (or a wall on the way).
signal arrived

## Walking speed in a cutscene, as a share of the run speed.
@export_range(0.1, 1.5) var walk_speed_factor := 0.6
## The player stops this close to the spot (px).
@export var arrive_distance := 1.0

var active := false
## Global x of the spot to walk to. NAN while standing.
var target_x := NAN
var _face_on_arrival := 0

@onready var player := owner as Player


func take() -> void:
	active = true
	target_x = NAN
	player.state_machine.transition_to(PlayerState.SCRIPTED)


## Walks to `x`, then turns to `facing` (-1 or 1; 0 keeps the walking direction).
func walk_to(x: float, facing := 0) -> void:
	target_x = x
	_face_on_arrival = facing


func is_walking() -> bool:
	return not is_nan(target_x)


## Called by the `Scripted` state when the walk is over.
func arrive() -> void:
	target_x = NAN
	if _face_on_arrival != 0:
		player.set_facing(_face_on_arrival)
	arrived.emit()


## Puts the player on `x` at once, for a skipped walk.
func place_at(x: float, facing := 0) -> void:
	target_x = NAN
	player.global_position.x = x
	player.velocity.x = 0.0
	player.reset_physics_interpolation()
	if facing != 0:
		player.set_facing(facing)


func release() -> void:
	if not active:
		return
	active = false
	target_x = NAN
	# Presses made during the cutscene don't carry over.
	player.consume_jump()
	player.consume_attack()
	var next := PlayerState.IDLE if player.is_on_floor() else PlayerState.FALL
	player.state_machine.transition_to(next)
