class_name BossAttack
extends EnemyAttackState
## One boss attack pattern. `Decide` picks among the boss's `BossAttack`
## states at random by `weight`, from those allowed in the current phase
## with the player between `min_range` and `max_range`. Timings follow the
## boss's phase (`Boss.time_scale()`).

## The phases this attack is used in.
@export_flags("Phase 1", "Phase 2", "Phase 3") var phases := 7
## Relative chance of being picked among the usable attacks.
@export var weight := 1.0
## Horizontal distance to the player it can start from (px).
@export var min_range := 0.0
@export var max_range := 60.0

@onready var boss := owner as Boss


## Allowed in this phase, with the player in range.
func can_use() -> bool:
	if phases & (1 << boss.phase) == 0:
		return false
	var distance := boss.distance_to_target()
	return distance >= min_range and distance <= max_range


func time_scale() -> float:
	return boss.time_scale()


func can_be_staggered() -> bool:
	return false
