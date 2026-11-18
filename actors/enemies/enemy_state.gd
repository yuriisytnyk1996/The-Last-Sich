class_name EnemyState
extends State
## Base for all enemy states: typed access to the Enemy and the state names
## every enemy shares. An enemy's attack state node is named "Attack".

const PATROL := &"Patrol"
const CHASE := &"Chase"
const ATTACK := &"Attack"
const HURT := &"Hurt"
const STUNNED := &"Stunned"
const EXECUTABLE := &"Executable"
const DEAD := &"Dead"

@onready var enemy := owner as Enemy


## Whether a NORMAL or HEAVY hit interrupts this state.
func can_be_staggered() -> bool:
	return true


## Where to go after a hit or an attack: keep fighting or go back to patrolling.
func alert_state() -> StringName:
	return enemy.alert_state()
