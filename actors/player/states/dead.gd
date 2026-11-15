extends PlayerState
## Health ran out. The body keeps its knockback, slides to a stop, and after
## `death_delay` the player_died event asks the room to respawn the player.

const DEAD_TINT := Color(0.45, 0.35, 0.35)

var _time_left := 0.0
var _announced := false


func enter(_previous_state: StringName) -> void:
	_time_left = player.death_delay
	_announced = false
	player.visual.modulate = DEAD_TINT


func exit() -> void:
	player.visual.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0 and not _announced:
		_announced = true
		Events.player_died.emit()
