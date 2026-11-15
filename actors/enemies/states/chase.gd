extends EnemyState
## Runs at the player, stopping at walls and ledges instead of falling off.
## Attacks once in range and off cooldown. Gives up when the player is
## further than `lose_range`, or has been out of sight for `lose_sight_time`.

var _unseen_time := 0.0


func enter(_previous_state: StringName) -> void:
	_unseen_time = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.face_target()
	if enemy.is_path_blocked() or enemy.is_target_in_attack_range():
		enemy.stop(delta)
	else:
		enemy.walk(delta, enemy.chase_speed)
	enemy.move_and_slide()

	_unseen_time = 0.0 if enemy.can_see_target() else _unseen_time + delta
	if not enemy.can_track_target() or _unseen_time >= enemy.lose_sight_time:
		finished.emit(PATROL)
	elif enemy.is_target_in_attack_range() and enemy.can_attack() and enemy.is_on_floor():
		finished.emit(ATTACK)
