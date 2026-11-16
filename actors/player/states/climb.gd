extends PlayerState
## On a ladder: up and down move along it, no gravity, no attacks.
##
## Reaching the top puts the player on the plank above (Idle), reaching the
## ground ends the climb, and running off the bottom lets go (Fall). Jump
## is a full jump off the ladder, straight up or to the side held; down +
## jump just lets go. One-way platforms are off while climbing so the
## player passes through them.

var _ladder: Ladder


func enter(_previous_state: StringName) -> void:
	_ladder = player.ladder_climb.ladder
	player.velocity = Vector2.ZERO
	player.global_position.x = _ladder.global_position.x
	# Grabbed in the air below its bottom: pull the feet up onto it.
	player.global_position.y = minf(player.global_position.y, _ladder.bottom())
	player.consume_jump()
	player.set_platforms_enabled(false)


func exit() -> void:
	player.set_platforms_enabled(true)


func physics_update(_delta: float) -> void:
	if not is_instance_valid(_ladder) and not _find_ladder_again():
		finished.emit(FALL)
		return
	# Re-applied every frame: a drop-through timer may switch it back on.
	player.set_platforms_enabled(false)
	if player.wants_jump():
		_jump_off()
		return

	# The input, not the velocity: move_and_slide() zeroes it at the floor.
	var direction := signf(player.get_vertical_axis())
	player.velocity = Vector2(0.0, direction * player.ladder_climb.climb_speed)
	player.move_and_slide()

	var feet := player.global_position.y
	if direction < 0.0 and feet <= _ladder.top():
		player.global_position.y = _ladder.top()
		player.velocity = Vector2.ZERO
		finished.emit(IDLE)
	elif direction > 0.0 and player.is_on_floor():
		finished.emit(IDLE)
	elif feet > _ladder.bottom():
		player.ladder_climb.let_go()
		finished.emit(FALL)


## The room changed while climbing: carry on with the ladder in the new room.
func _find_ladder_again() -> bool:
	_ladder = player.ladder_climb.refind()
	if _ladder == null:
		return false
	player.global_position.x = _ladder.global_position.x
	return true


func _jump_off() -> void:
	if player.get_vertical_axis() >= player.ladder_climb.grab_threshold:
		player.ladder_climb.let_go()
		player.consume_jump()
		finished.emit(FALL)
		return
	player.ladder_climb.jump_off()
	var axis := player.get_move_axis()
	if axis != 0.0:
		player.set_facing(axis)
	player.velocity.x = axis * player.run_speed
	finished.emit(JUMP)
