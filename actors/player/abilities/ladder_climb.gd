class_name PlayerLadderClimb
extends Node
## Finds ladders to grab and holds the climbing tuning. The Climb state
## does the climbing itself.

## Climbing speed up and down (px/s).
@export var climb_speed := 80.0
## How far from a ladder's centre the player can be and still grab it (px).
@export var grab_reach := 8.0
## How far up the body a ladder can be grabbed from (px above the feet).
## A ladder that ends above the feet but reaches this high is grabbed, and
## the player is pulled up onto its bottom.
@export var grab_height := 24.0
## Vertical input needed to grab a ladder from the ground (0 to 1).
@export_range(0.0, 1.0) var grab_threshold := 0.5
## Vertical input needed to grab a ladder in the air (0 to 1). Lower, so a
## diagonal held while jumping at a ladder still catches it.
@export_range(0.0, 1.0) var air_grab_threshold := 0.25
## After letting go (down + jump, or off the bottom), ladders can't be
## grabbed for this long (s).
@export var regrab_delay := 0.5

## The ladder to climb, set by the `wants_grab_*()` checks.
var ladder: Ladder

var _regrab_timer := 0.0
var _jumped_off := false

@onready var player := owner as Player


func _physics_process(delta: float) -> void:
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)
	# Velocity only: on the jump's first frame the player may still be on the floor.
	if _jumped_off and player.velocity.y >= 0.0:
		_jumped_off = false


## Up held over a ladder that goes on above the feet (from the ground or
## in the air).
func wants_grab_up() -> bool:
	if _regrab_blocked() or player.get_vertical_axis() > -_grab_threshold():
		return false
	var feet := player.global_position
	ladder = Ladder.find_at(get_tree(), feet, grab_reach, grab_height)
	return ladder != null and feet.y > ladder.top() + 2.0


## Down held while standing on top of a ladder.
func wants_grab_down() -> bool:
	if not player.is_on_floor() or player.get_vertical_axis() < grab_threshold:
		return false
	ladder = Ladder.find_top_at(get_tree(), player.global_position, grab_reach)
	return ladder != null


## Finds the ladder under the player again, after a room change.
func refind() -> Ladder:
	ladder = Ladder.find_at(get_tree(), player.global_position, grab_reach)
	return ladder


## Jumped off: no grabbing while the jump still rises, so holding up gives
## a hop up the ladder that catches it again at the top of the jump.
func jump_off() -> void:
	_jumped_off = true


## Let go without a jump: no grabbing for `regrab_delay`.
func let_go() -> void:
	_regrab_timer = regrab_delay


func reset() -> void:
	_regrab_timer = 0.0
	_jumped_off = false
	ladder = null


func _regrab_blocked() -> bool:
	return _regrab_timer > 0.0 or _jumped_off


func _grab_threshold() -> float:
	return grab_threshold if player.is_on_floor() else air_grab_threshold
