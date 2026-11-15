extends EnemyState
## Staggered by a hit: slides back with no control for a moment, then goes
## after the player. Knockback and length come from EnemyDamage, which
## already turned the enemy to face the hit.

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	enemy.velocity.x = enemy.damage.knockback
	_time_left = enemy.damage.stagger_time


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.stop(delta)
	enemy.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit(alert_state())
