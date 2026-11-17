extends PlayerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontally(delta, player.acceleration, player.friction)
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALL)
	elif player.ladder_climb.wants_grab_up() or player.ladder_climb.wants_grab_down():
		finished.emit(CLIMB)
	elif player.drop_through.wants():
		player.drop_through.start()
		finished.emit(FALL)
	elif player.wants_jump():
		finished.emit(JUMP)
	elif player.wants_dash():
		finished.emit(DASH)
	elif player.parry.wants():
		finished.emit(PARRY)
	elif player.skills.ranged.wants():
		finished.emit(RANGED)
	elif player.dumas.wants():
		finished.emit(DUMA)
	elif player.wants_attack():
		finished.emit(attack_state())
	elif player.flasks.wants():
		finished.emit(HEAL)
	elif player.get_move_axis() == 0.0:
		finished.emit(IDLE)
