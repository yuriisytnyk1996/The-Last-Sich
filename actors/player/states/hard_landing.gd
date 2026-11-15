extends PlayerState
## Landed after a long fall: the player is stuck in place for
## `hard_landing_time` while the camera shakes. Past
## `hard_landing_dash_cancel` of it, a dash gets them out early.

const SHAKE := 0.5

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	_time_left = player.hard_landing_time
	player.velocity.x = 0.0
	Events.camera_shake_requested.emit(SHAKE)


func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	player.apply_gravity(delta)
	player.move_and_slide()

	_time_left -= delta
	var cancel_at := player.hard_landing_time * (1.0 - player.hard_landing_dash_cancel)
	if not player.is_on_floor():
		finished.emit(FALL)
	elif _time_left <= cancel_at and player.wants_dash():
		finished.emit(DASH)
	elif _time_left <= 0.0:
		finished.emit(ground_state())
