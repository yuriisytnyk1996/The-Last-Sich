extends EnemyState
## Brought to its knees by a lethal hit (see `EnemyDamage`): left at 1
## health, slumped and harmless, with an `Execution` over it. The player
## can press interact there for a finisher, or just hit it: after
## `EnemyDamage.execution_safe_time` any hit kills it. Left alone for
## `execution_window`, it gets up with part of its health back.

const EXECUTION_SCENE := preload("res://components/interaction/execution.tscn")
## Placeholder slump: the body squashed down to this height.
const KNEEL_SCALE := 0.65

var _execution: Execution
var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	enemy.velocity.x = 0.0
	enemy.contact.set_active(false)
	enemy.hurtbox.set_invincible_for(enemy.damage.execution_safe_time)
	enemy.visual.scale.y = KNEEL_SCALE
	_time_left = enemy.damage.execution_window
	_execution = EXECUTION_SCENE.instantiate() as Execution
	_execution.executed.connect(_on_executed)
	# Deferred: this starts inside a physics callback (the lethal hit).
	enemy.add_child.call_deferred(_execution)


func exit() -> void:
	enemy.visual.scale.y = 1.0
	enemy.contact.set_active(true)
	if is_instance_valid(_execution):
		_execution.queue_free()
	_execution = null


func can_be_staggered() -> bool:
	return false


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	enemy.stop(delta)
	enemy.move_and_slide()

	if _execution.is_in_use():
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_recover()


## Gets up with `recover_health` of its maximum.
func _recover() -> void:
	var health := enemy.health
	var target := roundi(health.max_health * enemy.damage.recover_health)
	health.heal(target - health.current)
	finished.emit(alert_state())


func _on_executed() -> void:
	enemy.health.kill()
