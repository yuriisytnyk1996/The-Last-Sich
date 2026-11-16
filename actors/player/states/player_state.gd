class_name PlayerState
extends State
## Base for all player states: typed access to the Player and the state names.

const IDLE := &"Idle"
const RUN := &"Run"
const JUMP := &"Jump"
const FALL := &"Fall"
const DASH := &"Dash"
const CLIMB := &"Climb"
const HARD_LANDING := &"HardLanding"
const HEAL := &"Heal"
const SIDE_ATTACK := &"SideAttack"
const UP_ATTACK := &"UpAttack"
const CROUCH_ATTACK := &"CrouchAttack"
const PARRY := &"Parry"
const RIPOSTE := &"Riposte"
const HURT := &"Hurt"
const DEAD := &"Dead"

@onready var player := owner as Player


## Pick Idle or Run after landing or finishing a dash.
func ground_state() -> StringName:
	return RUN if player.get_move_axis() != 0.0 else IDLE


## Pick the attack from the vertical input at the moment of the press.
## Down only means a crouch attack on the ground; in the air it's a side slash.
func attack_state() -> StringName:
	var vertical := player.get_vertical_axis()
	if vertical <= -player.attack_vertical_threshold:
		return UP_ATTACK
	if vertical >= player.attack_vertical_threshold and player.is_on_floor():
		return CROUCH_ATTACK
	return SIDE_ATTACK
