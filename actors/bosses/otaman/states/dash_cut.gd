extends BossAttack
## Draws back, then dashes along the floor with the blade low and out,
## stopping at walls and ledges. Can't be parried: jump over it or dash
## through it.

## Speed of the dash while the blade is out (px/s).
@export var dash_speed := 320.0


func move(delta: float) -> void:
	if _phase == Phase.ACTIVE and not enemy.is_path_blocked():
		enemy.velocity.x = enemy.facing * dash_speed
	else:
		enemy.stop(delta)
