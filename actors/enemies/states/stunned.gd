extends EnemyState
## Its attack was parried: pushed back a little, then helpless for
## `EnemyDamage.stun_time`. Poise is restored, so any hit staggers it,
## and a riposte lands in full.

## Placeholder shown above the head while stunned. Optional.
@export var mark: CanvasItem

var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	enemy.velocity.x = enemy.damage.knockback
	_time_left = enemy.damage.stun_time
	enemy.damage.reset_poise()
	if mark:
		mark.visible = true


func exit() -> void:
	if mark:
		mark.visible = false


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.stop(delta)
	enemy.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		finished.emit(alert_state())
