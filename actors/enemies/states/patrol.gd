extends EnemyState
## Walks back and forth. At a wall or ledge it stops, waits `turn_pause`
## and turns around. Switches to Chase as soon as it sees the player.

var _pause_left := 0.0


func enter(_previous_state: StringName) -> void:
	_pause_left = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	_walk_or_turn(delta)
	enemy.move_and_slide()

	if enemy.can_see_target():
		finished.emit(CHASE)


func _walk_or_turn(delta: float) -> void:
	if _pause_left > 0.0:
		enemy.stop(delta)
		_pause_left -= delta
		if _pause_left <= 0.0:
			enemy.turn_around()
	elif enemy.is_path_blocked():
		enemy.stop(delta)
		_pause_left = enemy.turn_pause
	else:
		enemy.walk(delta, enemy.patrol_speed)
