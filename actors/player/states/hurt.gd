extends PlayerState
## Staggered by a hit: knocked back with no control for a moment.
##
## Knockback and length come from PlayerDamage, which already turned the
## player to face the hit. The hurtbox stays invincible for the whole
## stagger, and for `invincibility_time` after it.

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	player.velocity = player.damage.knockback
	_time_left = player.damage.stagger_time
	player.hurtbox.set_invincible_for(INF)


func exit() -> void:
	player.hurtbox.set_invincible_for(player.damage.invincibility_time)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
	player.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit(ground_state() if player.is_on_floor() else FALL)
