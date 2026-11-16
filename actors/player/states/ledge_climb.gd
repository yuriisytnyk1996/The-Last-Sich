extends PlayerState
## Pulling up from a ledge hang onto the top.
##
## Two straight moves so the body never cuts into the wall: first up beside
## the wall until the feet reach the ledge top, then sideways onto it. No
## input is read; a hit still knocks the player off into Hurt.

var _time := 0.0
var _start := Vector2.ZERO
var _corner_side := Vector2.ZERO
var _stand := Vector2.ZERO


func enter(_previous_state: StringName) -> void:
	_time = 0.0
	var ledge := player.ledge_grab
	_start = player.global_position
	_stand = ledge.stand_position()
	_corner_side = Vector2(_start.x, _stand.y)
	player.velocity = Vector2.ZERO
	player.consume_jump()


func physics_update(delta: float) -> void:
	_time += delta
	var ledge := player.ledge_grab
	var rise := ledge.climb_rise_time
	if _time < rise:
		player.global_position = _start.lerp(_corner_side, _ease(_time / rise))
		return
	var over := clampf((_time - rise) / ledge.climb_over_time, 0.0, 1.0)
	player.global_position = _corner_side.lerp(_stand, _ease(over))
	if over >= 1.0:
		player.consume_jump()
		finished.emit(ground_state())


func _ease(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)
