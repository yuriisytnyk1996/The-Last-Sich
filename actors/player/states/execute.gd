extends PlayerState
## The finisher on an `Execution` (see `PlayerExecutions`): step up to it,
## blade raised for `windup`, the blow, then `recovery`. Planted and
## invincible from start to finish, and for `PlayerParry.grace_time` after.

## Placeholder blade held overhead during the wind-up.
@export var raised: CanvasItem
## Placeholder cut shown after the blow.
@export var cut: CanvasItem

var _execution: Execution
var _struck := false
var _time_left := 0.0


func enter(_previous_state: StringName) -> void:
	_execution = player.executions.take_target()
	_struck = false
	_time_left = player.executions.windup
	player.hurtbox.set_invincible_for(INF)
	player.velocity = Vector2.ZERO
	var dx := _execution.global_position.x - player.global_position.x
	player.set_facing(dx if dx != 0.0 else float(player.facing))
	# Collides on the way, so a wall behind the target stops the step.
	var spot := _execution.global_position.x - player.facing * player.executions.distance
	player.move_and_collide(Vector2(spot - player.global_position.x, 0.0))
	raised.visible = true


func exit() -> void:
	raised.visible = false
	cut.visible = false
	if not _struck and is_instance_valid(_execution):
		_execution.release()
	_execution = null
	player.hurtbox.set_invincible_for(player.parry.grace_time)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = 0.0
	player.move_and_slide()

	_time_left -= delta
	if _time_left > 0.0:
		return
	if not _struck:
		_strike()
		return
	finished.emit(ground_state())


func _strike() -> void:
	_struck = true
	raised.visible = false
	cut.visible = true
	_time_left = player.executions.recovery
	if is_instance_valid(_execution):
		_execution.strike()
	player.executions.reward()
