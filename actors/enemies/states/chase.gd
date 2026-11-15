extends EnemyState
## Runs at the player, stopping at walls and ledges instead of falling off.
## Attacks once in range and off cooldown.
##
## A chase that can't get anywhere (the player is on another level, or a
## wall or ledge is in the way) stands and watches for `give_up_time`, then
## the enemy turns away and patrols again. It also gives up when the player
## is further than `lose_range`, or out of sight for `lose_sight_time`.

var _unseen_time := 0.0
var _stuck_time := 0.0


func enter(_previous_state: StringName) -> void:
	_unseen_time = 0.0
	_stuck_time = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.face_target()
	var in_range := enemy.is_target_in_attack_range()
	var stuck := not in_range and (enemy.is_path_blocked() or not enemy.can_reach_target())
	if stuck or in_range:
		enemy.stop(delta)
	else:
		enemy.walk(delta, enemy.chase_speed)
	enemy.move_and_slide()

	_unseen_time = 0.0 if enemy.can_see_target() else _unseen_time + delta
	_stuck_time = _stuck_time + delta if stuck else 0.0
	if _stuck_time >= enemy.give_up_time:
		enemy.turn_around()
		finished.emit(PATROL)
	elif not enemy.can_track_target() or _unseen_time >= enemy.lose_sight_time:
		finished.emit(PATROL)
	elif in_range and enemy.can_attack() and enemy.is_on_floor():
		finished.emit(ATTACK)
