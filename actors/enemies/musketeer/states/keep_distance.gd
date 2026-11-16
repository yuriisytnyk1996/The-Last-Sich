extends EnemyState
## The musketeer's Chase: holds the player at musket range.
##
## Too close, it backs away facing the player, unless a wall or a ledge is
## behind it. Out of range, it walks closer. In range, it stands. It fires
## when in range, off cooldown, on the floor and with a clear line of sight;
## backed into a corner, it fires at point-blank range.
##
## Gives up like the shared Chase: the player too far (`lose_range`), out of
## sight for `lose_sight_time`, or out of reach for `give_up_time`.

var _unseen_time := 0.0
var _stuck_time := 0.0

@onready var musketeer := owner as Musketeer


func enter(_previous_state: StringName) -> void:
	_unseen_time = 0.0
	_stuck_time = 0.0


func physics_update(delta: float) -> void:
	musketeer.apply_gravity(delta)
	musketeer.face_target()
	var in_range := musketeer.is_target_in_attack_range()
	var backing := musketeer.is_target_too_close() and not musketeer.is_retreat_blocked()
	var stuck := not in_range and (musketeer.is_path_blocked() or not musketeer.can_reach_target())
	if backing:
		musketeer.retreat(delta)
	elif stuck or in_range:
		musketeer.stop(delta)
	else:
		musketeer.walk(delta, musketeer.chase_speed)
	musketeer.move_and_slide()

	var sees := musketeer.can_see_target()
	_unseen_time = 0.0 if sees else _unseen_time + delta
	_stuck_time = _stuck_time + delta if stuck else 0.0
	if _stuck_time >= musketeer.give_up_time:
		musketeer.turn_around()
		finished.emit(PATROL)
	elif not musketeer.can_track_target() or _unseen_time >= musketeer.lose_sight_time:
		finished.emit(PATROL)
	elif _can_fire(in_range, sees, backing):
		finished.emit(ATTACK)


func _can_fire(in_range: bool, sees: bool, backing: bool) -> bool:
	if not (in_range and sees and musketeer.can_attack() and musketeer.is_on_floor()):
		return false
	return not backing
