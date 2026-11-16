extends PlayerState
## Hanging from a ledge by the hands: no gravity, no movement.
##
## After `climb_delay`, up or jump climbs onto the ledge (LedgeClimb).
## Down lets go (Fall), and the ledge can't be grabbed again for a moment.

var _time := 0.0


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	var ledge := player.ledge_grab
	player.velocity = Vector2.ZERO
	player.global_position = ledge.hang_position()
	player.set_facing(ledge.side)
	player.consume_jump()
	player.consume_attack()


func physics_update(delta: float) -> void:
	_time += delta
	var ledge := player.ledge_grab
	var vertical := player.get_vertical_axis()
	if vertical >= ledge.input_threshold:
		ledge.let_go()
		finished.emit(FALL)
	elif _time >= ledge.climb_delay and _wants_climb(vertical):
		finished.emit(LEDGE_CLIMB)


func _wants_climb(vertical: float) -> bool:
	return player.wants_jump() or vertical <= -player.ledge_grab.input_threshold
