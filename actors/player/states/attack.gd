extends PlayerState
## One swing in three phases: startup (wind-up), active (hitbox on) and
## recovery. Facing is locked for the whole swing so the hitbox never flips
## mid-attack. On the ground the player slows down; in the air they keep
## air control.

enum Phase { STARTUP, ACTIVE, RECOVERY }

var _phase := Phase.STARTUP
var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	player.consume_attack()
	_phase = Phase.STARTUP
	_time_left = player.attack_startup


func exit() -> void:
	# Also runs when the swing is interrupted (e.g. by a respawn).
	player.attack_hitbox.set_active(false)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	_move(delta)
	player.move_and_slide()

	_time_left -= delta
	if _time_left > 0.0:
		return

	match _phase:
		Phase.STARTUP:
			player.attack_hitbox.set_active(true)
			_phase = Phase.ACTIVE
			_time_left = player.attack_active
		Phase.ACTIVE:
			player.attack_hitbox.set_active(false)
			_phase = Phase.RECOVERY
			_time_left = player.attack_recovery
		Phase.RECOVERY:
			finished.emit(ground_state() if player.is_on_floor() else FALL)


func _move(delta: float) -> void:
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	else:
		var target := player.get_move_axis() * player.run_speed
		player.velocity.x = move_toward(player.velocity.x, target, player.air_acceleration * delta)
