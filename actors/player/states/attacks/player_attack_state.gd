class_name PlayerAttackState
extends PlayerState
## Shared timing for every player attack: startup (wind-up), active (hitbox
## on) and recovery. Subclasses only decide how the player moves and turns
## during the swing.
##
## A swing that missed can be cut short: pressing attack during recovery
## starts the next swing right away. A swing that hit plays out in full.

enum Phase { STARTUP, ACTIVE, RECOVERY }

## The hitbox this attack turns on, under Visual/Attacks in the player scene.
@export var hitbox: Hitbox

var _phase := Phase.STARTUP
var _time_left := 0.0
var _started_on_floor := false


func enter(_previous_state: StringName) -> void:
	player.consume_attack()
	_started_on_floor = player.is_on_floor()
	_phase = Phase.STARTUP
	_time_left = player.attack_startup


func exit() -> void:
	# Also runs when the swing is interrupted (e.g. by a respawn).
	hitbox.set_active(false)


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	move(delta)
	player.move_and_slide()

	if _phase == Phase.RECOVERY and player.wants_attack() and not hitbox.has_hit():
		finished.emit(attack_state())
		return

	_time_left -= delta
	if _time_left > 0.0:
		return

	match _phase:
		Phase.STARTUP:
			hitbox.set_active(true)
			_phase = Phase.ACTIVE
			_time_left = player.attack_active
		Phase.ACTIVE:
			hitbox.set_active(false)
			_phase = Phase.RECOVERY
			_time_left = player.attack_recovery
		Phase.RECOVERY:
			finished.emit(ground_state() if player.is_on_floor() else FALL)


## Default movement, facing locked. A swing started on the ground plants
## the player: they stop dead and can't walk until it ends. A swing started
## in the air keeps full air control.
func move(delta: float) -> void:
	if _started_on_floor:
		player.velocity.x = 0.0
		return
	var target := player.get_move_axis() * player.run_speed
	player.velocity.x = move_toward(player.velocity.x, target, player.air_acceleration * delta)
