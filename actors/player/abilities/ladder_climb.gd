class_name PlayerLadderClimb
extends Node
## Finds ladders to grab and holds the climbing tuning. The Climb state
## does the climbing itself.

## Climbing speed up and down (px/s).
@export var climb_speed := 80.0
## How far from a ladder's centre the player can be and still grab it (px).
@export var grab_reach := 8.0
## Vertical input needed to grab a ladder (0 to 1).
@export_range(0.0, 1.0) var grab_threshold := 0.5
## After jumping off or letting go, ladders can't be grabbed for this long (s).
@export var regrab_delay := 0.3

## The ladder to climb, set by the `wants_grab_*()` checks.
var ladder: Ladder

var _regrab_timer := 0.0

@onready var player := owner as Player


func _physics_process(delta: float) -> void:
	_regrab_timer = maxf(_regrab_timer - delta, 0.0)


## Up held over a ladder that goes on above the feet (from the ground or
## in the air).
func wants_grab_up() -> bool:
	if _regrab_timer > 0.0 or player.get_vertical_axis() > -grab_threshold:
		return false
	ladder = Ladder.find_at(get_tree(), player.global_position, grab_reach)
	return ladder != null and player.global_position.y > ladder.top() + 2.0


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


func let_go() -> void:
	_regrab_timer = regrab_delay


func reset() -> void:
	_regrab_timer = 0.0
	ladder = null
