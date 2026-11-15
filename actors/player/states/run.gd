extends PlayerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontally(delta, player.acceleration, player.friction)
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALL)
	elif player.wants_jump():
		finished.emit(JUMP)
	elif player.wants_dash():
		finished.emit(DASH)
	elif player.get_move_axis() == 0.0:
		finished.emit(IDLE)
