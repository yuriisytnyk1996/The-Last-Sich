extends EnemyAttackState
## A forward saber cut. The raider stands still through the wind-up, lunges
## forward while the blade is out (never off a ledge), then recovers.

## Forward speed during the active window (px/s).
@export var lunge_speed := 120.0


func move(delta: float) -> void:
	if _phase == Phase.ACTIVE and not enemy.is_path_blocked():
		enemy.velocity.x = enemy.facing * lunge_speed
	else:
		enemy.stop(delta)
