extends PlayerState
## Clinging to a climb wall: slides down a little, then holds still. The
## slide stops early where the wall ends, so a grab at the very bottom of
## a wall holds instead of slipping off.
##
## Jump kicks off it (WallJump). Down lets go (Fall), and no wall can be
## grabbed again for a moment. Losing the wall (out of the climb wall, or
## a gate opening under the hands) also falls; reaching the floor stands.

var _time := 0.0


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	var wall := player.wall_jump
	player.velocity = Vector2.ZERO
	player.global_position.x = wall.cling_x()
	player.set_facing(wall.side)
	# The attack press that grabbed is used up. A jump buffered just before
	# the grab is kept: it kicks off at once.
	player.consume_attack()


func physics_update(delta: float) -> void:
	var wall := player.wall_jump
	_time += delta
	var speed := _slide_speed()
	if speed > 0.0 and not wall.is_holding(Vector2(0.0, speed * delta)):
		speed = 0.0
		_time = wall.slide_time
	player.velocity = Vector2(0.0, speed)
	player.move_and_slide()

	if player.wants_jump():
		finished.emit(WALL_JUMP)
	elif player.get_vertical_axis() >= wall.let_go_threshold:
		wall.let_go()
		finished.emit(FALL)
	elif player.is_on_floor():
		finished.emit(ground_state())
	elif not wall.is_holding():
		wall.let_go()
		finished.emit(FALL)


## Covers `slide_distance` over `slide_time`, fast at first, then stops.
func _slide_speed() -> float:
	var wall := player.wall_jump
	if wall.slide_time <= 0.0 or _time >= wall.slide_time:
		return 0.0
	return 2.0 * wall.slide_distance / wall.slide_time * (1.0 - _time / wall.slide_time)
