extends PlayerState

var _jump_cut := false


func enter(_previous_state: StringName) -> void:
	_jump_cut = false
	player.velocity.y = player.jump_velocity
	player.consume_jump()


func physics_update(delta: float) -> void:
	# Variable jump height: releasing the button early cuts the jump short.
	if not _jump_cut and player.velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		player.velocity.y *= player.jump_cut_multiplier
		_jump_cut = true

	player.apply_gravity(delta)
	player.move_horizontally(delta, player.air_acceleration, player.air_acceleration)
	player.move_and_slide()

	if player.ladder_climb.wants_grab_up():
		finished.emit(CLIMB)
	elif player.skills.ranged.wants():
		finished.emit(RANGED)
	elif player.skills.dive.wants():
		finished.emit(DIVE)
	elif player.wants_attack():
		finished.emit(attack_state())
	elif player.velocity.y >= 0.0:
		finished.emit(FALL)
