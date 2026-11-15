extends PlayerState
## A fast, straight burst along the ground in the input direction (or the
## facing direction). No gravity. Ground only: running off a ledge ends it
## at once and the player falls with normal air control.

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	var axis := player.get_move_axis()
	if axis != 0.0:
		player.set_facing(axis)
	player.start_dash()
	player.velocity = Vector2(player.facing * player.dash_speed, 0.0)
	_time_left = player.dash_duration


func physics_update(delta: float) -> void:
	_time_left -= delta
	player.move_and_slide()
	if not player.is_on_floor():
		player.velocity.x = player.facing * player.run_speed
		finished.emit(FALL)
	elif _time_left <= 0.0:
		player.velocity.x = player.facing * player.run_speed
		finished.emit(ground_state())
