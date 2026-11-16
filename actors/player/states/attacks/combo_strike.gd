class_name PlayerComboStrike
extends PlayerAttackState
## A heavy combo swing with its own timing: the end of the ground combo
## and the finishers learned as skills. Steps forward during the wind-up
## (`lunge_speed`) and can hop the player up as it starts (`rise_speed`).
## Facing is locked.

@export var startup := 0.08
@export var active := 0.12
@export var recovery := 0.28
## Forward speed during the wind-up on the ground (px/s).
@export var lunge_speed := 0.0
## Upward speed given when the swing starts on the ground (px/s).
@export var rise_speed := 0.0


func enter(previous_state: StringName) -> void:
	super.enter(previous_state)
	if rise_speed > 0.0 and player.is_on_floor():
		player.velocity.y = -rise_speed


func startup_time() -> float:
	return startup


func active_time() -> float:
	return active


func recovery_time() -> float:
	return recovery


func move(_delta: float) -> void:
	var lunging := _phase == Phase.STARTUP and _started_on_floor
	player.velocity.x = player.facing * lunge_speed if lunging else 0.0
