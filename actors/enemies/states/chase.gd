extends EnemyState
## Runs at the player, stopping at walls and ledges instead of falling off.
## Attacks once in range and off cooldown, gives up when the player is
## further than `lose_range`.


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.face_target()
	if enemy.is_path_blocked() or enemy.is_target_in_attack_range():
		enemy.stop(delta)
	else:
		enemy.walk(delta, enemy.chase_speed)
	enemy.move_and_slide()

	if not enemy.can_track_target():
		finished.emit(PATROL)
	elif enemy.is_target_in_attack_range() and enemy.can_attack() and enemy.is_on_floor():
		finished.emit(ATTACK)
