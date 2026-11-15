extends PlayerState
## Health ran out. The body keeps its knockback, slides to a stop, and after
## `death_delay` the player_died event asks the world to respawn the player.
##
## Fell into a pit (below the room's bottom edge): the body stops dead where
## it is, so it doesn't drift under the floor with the speed it had and drag
## the camera along. No input is read while dead.

const DEAD_TINT := Color(0.45, 0.35, 0.35)

var _time_left := 0.0
var _announced := false
var _in_pit := false


func enter(_previous_state: StringName) -> void:
	_time_left = player.damage.death_delay
	_announced = false
	_in_pit = player.global_position.y > player.camera.limit_bottom
	if _in_pit:
		player.velocity = Vector2.ZERO
	# On the root, so it multiplies with the hit flash on Visual.
	player.modulate = DEAD_TINT


func exit() -> void:
	player.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	if not _in_pit:
		player.apply_gravity(delta)
		if player.is_on_floor():
			player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
		player.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0 and not _announced:
		_announced = true
		Events.player_died.emit()
