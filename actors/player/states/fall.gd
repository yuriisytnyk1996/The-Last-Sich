extends PlayerState
## In the air, moving down or at the top of a jump. Measures how far the
## player falls, so a long drop ends in a hard landing.

var _fall_distance := 0.0


func enter(_previous_state: StringName) -> void:
	_fall_distance = 0.0


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_horizontally(delta, player.air_acceleration, player.air_acceleration)
	player.move_and_slide()
	if player.velocity.y > 0.0:
		_fall_distance += player.velocity.y * delta

	if player.wants_jump() and player.has_coyote_time():
		finished.emit(JUMP)
	elif player.ladder_climb.wants_grab_up():
		finished.emit(CLIMB)
	elif player.ledge_grab.wants_grab():
		finished.emit(LEDGE_HANG)
	elif player.wants_attack():
		finished.emit(attack_state())
	elif player.is_on_floor():
		var hard := _fall_distance >= player.hard_landing_height
		finished.emit(HARD_LANDING if hard else ground_state())
