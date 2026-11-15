class_name PlayerState
extends State
## Base for all player states: typed access to the Player and the state names.

const IDLE := &"Idle"
const RUN := &"Run"
const JUMP := &"Jump"
const FALL := &"Fall"
const DASH := &"Dash"

@onready var player := owner as Player


## Pick Idle or Run after landing or finishing a dash.
func ground_state() -> StringName:
	return RUN if player.get_move_axis() != 0.0 else IDLE
