extends EnemyState
## The crow's Patrol: flies back and forth around its spawn point with a
## gentle bob, turning at `patrol_distance` or a wall. After a chase it
## flies back the same way, since it turns towards home once past the edge.
## Switches to Pursue (Chase) as soon as it sees the player.

## Seconds after a turn before it can turn again, so it doesn't flicker
## at the edge of its range.
const TURN_LOCK := 0.4

var _time := 0.0
var _turn_lock := 0.0

@onready var crow := owner as Crow


func enter(_previous_state: StringName) -> void:
	_turn_lock = 0.0


func physics_update(delta: float) -> void:
	_time += delta
	_turn_lock = maxf(_turn_lock - delta, 0.0)
	var home := crow.home_position()
	var from_home := crow.global_position.x - home.x
	var past_edge := absf(from_home) >= crow.patrol_distance and signf(from_home) == crow.facing
	if _turn_lock <= 0.0 and (past_edge or crow.is_path_blocked()):
		crow.turn_around()
		_turn_lock = TURN_LOCK

	var bob := sin(_time * TAU * crow.bob_speed) * crow.bob_height
	var ahead := Vector2(crow.global_position.x + crow.facing * 32.0, home.y + bob)
	crow.fly_toward(ahead, crow.patrol_speed, delta)
	crow.move_and_slide()

	if crow.can_see_target():
		finished.emit(CHASE)
