extends PlayerAttackState
## A dash turned into a thrust (see `PlayerLungeAttack`). The hitbox is on
## for the whole drive forward; speed, length and damage come from the
## lunge level. Contact damage passes through while it lasts. Leaving the
## ground stops the forward drive.

@export var startup := 0.03
@export var recovery := 0.2

var _speed := 0.0
var _duration := 0.0


func enter(previous_state: StringName) -> void:
	var lunge := player.skills.lunge
	_speed = lunge.speed()
	_duration = lunge.duration()
	hitbox.damage = lunge.damage()
	super.enter(previous_state)
	player.hurtbox.ignore_continuous = true


func exit() -> void:
	super.exit()
	player.hurtbox.ignore_continuous = false


func startup_time() -> float:
	return startup


func active_time() -> float:
	return _duration


func recovery_time() -> float:
	return recovery


func move(_delta: float) -> void:
	var driving := _phase != Phase.RECOVERY and player.is_on_floor()
	player.velocity.x = player.facing * _speed if driving else 0.0
