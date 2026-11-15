extends PlayerState

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	var axis := player.get_move_axis()
	if axis != 0.0:
		player.set_facing(axis)
	player.start_dash()
	player.velocity = Vector2(player.facing * player.dash_speed, 0.0)
	_time_left = player.dash_duration


func physics_update(delta: float) -> void:
	# No gravity during a dash: a straight, snappy burst.
	_time_left -= delta
	player.move_and_slide()
	if _time_left > 0.0:
		return

	player.velocity.x = player.facing * player.run_speed
	finished.emit(ground_state() if player.is_on_floor() else FALL)
