extends PlayerState


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontally(delta, player.air_acceleration, player.air_acceleration)
	player.move_and_slide()

	if player.wants_jump() and player.has_coyote_time():
		finished.emit(JUMP)
	elif player.wants_dash():
		finished.emit(DASH)
	elif player.wants_attack():
		finished.emit(ATTACK)
	elif player.is_on_floor():
		finished.emit(ground_state())
