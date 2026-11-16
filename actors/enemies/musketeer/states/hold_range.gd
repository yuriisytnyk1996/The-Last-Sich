extends EnemyState
## The musketeer's Chase: plants itself and makes the player come to it.
##
## Out of range, it walks closer (never off a ledge). Once it can aim at
## the player (`MusketShot.can_aim()`: in range, in sight and within the
## aim angle) it stands and fires whenever the cooldown allows. It never
## backs away: a player who closes in gets a free kill.
##
## A player it can't aim at and can't walk closer to (under its ledge,
## up on a platform, behind cover) leaves it stuck: it stands facing them
## and gives up after `give_up_time`, like the shared Chase. It also gives
## up when the player is further than `lose_range`, or out of sight for
## `lose_sight_time`.

## The attack state, asked whether the player can be aimed at.
@export var shot: MusketShot

var _unseen_time := 0.0
var _stuck_time := 0.0


func enter(_previous_state: StringName) -> void:
	_unseen_time = 0.0
	_stuck_time = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.face_target()
	var aimable := shot.can_aim()
	var approach := not aimable and _can_approach()
	if approach:
		enemy.walk(delta, enemy.chase_speed)
	else:
		enemy.stop(delta)
	enemy.move_and_slide()

	var stuck := not aimable and not approach
	_unseen_time = 0.0 if enemy.can_see_target() else _unseen_time + delta
	_stuck_time = _stuck_time + delta if stuck else 0.0
	if _stuck_time >= enemy.give_up_time:
		enemy.turn_around()
		finished.emit(PATROL)
	elif not enemy.can_track_target() or _unseen_time >= enemy.lose_sight_time:
		finished.emit(PATROL)
	elif aimable and enemy.can_attack() and enemy.is_on_floor():
		finished.emit(ATTACK)


## Out of range, on its level, with nothing in the way.
func _can_approach() -> bool:
	if enemy.is_target_in_attack_range() or not enemy.can_reach_target():
		return false
	return not enemy.is_path_blocked()
