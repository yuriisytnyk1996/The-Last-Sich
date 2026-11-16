extends PlayerAttackState
## The counter-attack after a parry: a quick lunge into a heavy slash while
## the attacker is stunned. Invincible from start to finish, and for
## `PlayerParry.grace_time` after.

@export var startup := 0.06
@export var active := 0.12
@export var recovery := 0.3
## Forward speed during the wind-up, closing the gap to the attacker (px/s).
@export var lunge_speed := 160.0


func enter(previous_state: StringName) -> void:
	super.enter(previous_state)
	player.hurtbox.set_invincible_for(INF)


func exit() -> void:
	super.exit()
	player.hurtbox.set_invincible_for(player.parry.grace_time)


func startup_time() -> float:
	return startup


func active_time() -> float:
	return active


func recovery_time() -> float:
	return recovery


func move(_delta: float) -> void:
	var lunging := _phase == Phase.STARTUP and player.is_on_floor()
	player.velocity.x = player.facing * lunge_speed if lunging else 0.0
