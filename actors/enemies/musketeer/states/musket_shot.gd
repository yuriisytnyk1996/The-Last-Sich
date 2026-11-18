class_name MusketShot
extends EnemyAttackState
## Aims the musket at the player, fires one ball, then a long reload.
##
## Through the wind-up the aim line (`telegraph`) follows the player's
## body, up to `max_aim_angle` above or below straight ahead. For the last
## `aim_lock` seconds the aim freezes, so a well-timed jump or step dodges
## the ball. The shot itself can't be parried. Recovery is the reload, the
## opening to close in.

## The ball fired when the wind-up ends.
@export var projectile_scene: PackedScene
## Where the ball leaves the barrel. Under Visual, so it flips with facing.
@export var muzzle: Node2D
## Rotated to show the aim. Under Visual; usually also the telegraph.
@export var aim_pivot: Node2D
## Seconds before the shot when the aim stops following the player.
@export var aim_lock := 0.2
## How far up or down from straight ahead it can aim (degrees).
@export_range(0.0, 80.0) var max_aim_angle := 35.0

## Aim in Visual's space: x always points ahead.
var _local_aim := Vector2.RIGHT


func _ready() -> void:
	super()
	Pool.prewarm(projectile_scene, 2)


## The player is in range, in sight, in front and within the aim angle.
func can_aim() -> bool:
	if not (enemy.is_target_in_attack_range() and enemy.can_see_target()):
		return false
	var local := _local_offset()
	return local.x > 0.0 and absf(local.angle()) <= deg_to_rad(max_aim_angle)


func enter(previous_state: StringName) -> void:
	super(previous_state)
	_local_aim = Vector2.RIGHT
	_follow_target()


func physics_update(delta: float) -> void:
	if _phase == Phase.STARTUP and _time_left > aim_lock:
		_follow_target()
	super(delta)


func _on_active() -> void:
	if projectile_scene == null:
		return
	var ball := Pool.take(projectile_scene) as EnemyProjectile
	ball.attacker_stats = enemy.stats
	var direction := Vector2(_local_aim.x * enemy.facing, _local_aim.y)
	ball.launch(muzzle.global_position, direction)
	enemy.get_parent().add_child(ball)


func _follow_target() -> void:
	if not enemy.can_track_target():
		return
	var local := _local_offset()
	var limit := deg_to_rad(max_aim_angle)
	var angle := clampf(local.angle(), -limit, limit) if local.x > 0.0 else 0.0
	_local_aim = Vector2.from_angle(angle)
	aim_pivot.rotation = angle


## Muzzle to the player's body, in Visual's space (x points ahead).
func _local_offset() -> Vector2:
	var to_target := enemy.target_point() - muzzle.global_position
	return Vector2(to_target.x * enemy.facing, to_target.y)
