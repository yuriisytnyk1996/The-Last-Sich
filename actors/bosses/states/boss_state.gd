class_name BossState
extends EnemyState
## Base for the shared boss states: typed access to the `Boss` and the
## names of the states every boss has. Attacks extend `BossAttack` instead.

const DORMANT := &"Dormant"
const DECIDE := &"Decide"
const ROAR := &"Roar"

@onready var boss := owner as Boss


func can_be_staggered() -> bool:
	return false
