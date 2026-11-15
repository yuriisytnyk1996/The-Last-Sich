extends PlayerState
## Knocked back by a hit. No control until `hurt_duration` ends.
##
## The player is thrown up and away from the hit and turns to face it.
## Invincibility runs on the Hurtbox and outlasts this state, so the player
## gets a moment to escape after control returns.

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	var direction := player.hurt_direction
	player.set_facing(-direction)
	player.velocity = Vector2(direction * player.hurt_knockback.x, -player.hurt_knockback.y)
	_time_left = player.hurt_duration


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit(ground_state() if player.is_on_floor() else FALL)
