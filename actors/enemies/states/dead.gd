extends EnemyState
## Health ran out. The enemy stops hurting and being hurt, slides to a stop,
## darkens and fades out. It stays gone until `Enemy.reset()`.

const DEAD_TINT := Color(0.45, 0.35, 0.35)

var _tween: Tween


func enter(_previous_state: StringName) -> void:
	enemy.set_combat_enabled(false)
	# On the root, so it multiplies with the hit flash on Visual.
	enemy.modulate = DEAD_TINT
	_tween = enemy.create_tween()
	_tween.tween_interval(enemy.damage.corpse_time)
	_tween.tween_property(enemy, "modulate:a", 0.0, enemy.damage.fade_time)


func exit() -> void:
	if _tween:
		_tween.kill()
	enemy.modulate = Color.WHITE
	enemy.set_combat_enabled(true)


func can_be_staggered() -> bool:
	return false


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.stop(delta)
	enemy.move_and_slide()
