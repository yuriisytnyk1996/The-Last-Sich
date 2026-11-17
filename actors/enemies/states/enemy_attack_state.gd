class_name EnemyAttackState
extends EnemyState
## Shared timing for enemy attacks: a readable wind-up with a telegraph,
## the active window (hitbox on), then recovery. Subclasses override
## `move()` to decide how the enemy moves during the attack, and
## `_on_active()` to do something when the wind-up ends (fire a shot).
##
## A hit during the wind-up interrupts the attack. Once the hitbox is out
## the attack is committed: hits still deal damage but don't stagger.
## A `parryable` hitbox that gets parried stuns the enemy instead.

enum Phase { STARTUP, ACTIVE, RECOVERY }

## The hitbox this attack turns on, under Visual/Attacks. Optional: a
## ranged attack spawns its projectile in `_on_active()` instead.
@export var hitbox: Hitbox
## Shown during the wind-up so the player can read the attack. Optional.
@export var telegraph: CanvasItem
## Wind-up before the hitbox turns on (s). Long enough to react to.
@export var startup := 0.45
@export var active := 0.12
@export var recovery := 0.5
## Time after the attack ends before the next one can start (s).
@export var cooldown := 0.6

var _phase := Phase.STARTUP
var _time_left := 0.0


func _ready() -> void:
	if hitbox:
		hitbox.parried.connect(_on_parried)


func enter(_previous_state: StringName) -> void:
	enemy.face_target()
	_phase = Phase.STARTUP
	_time_left = startup * time_scale()
	_show_telegraph(true)


func exit() -> void:
	# Also runs when the attack is interrupted by a hit or a reset.
	_set_hitbox_active(false)
	_show_telegraph(false)
	enemy.start_attack_cooldown(cooldown)


func can_be_staggered() -> bool:
	return _phase == Phase.STARTUP and not enemy.damage.is_poise_broken()


func physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	move(delta)
	enemy.move_and_slide()

	_time_left -= delta
	if _time_left <= 0.0:
		_next_phase()


## Default movement: stand still for the whole attack.
func move(delta: float) -> void:
	enemy.stop(delta)


func _next_phase() -> void:
	match _phase:
		Phase.STARTUP:
			_show_telegraph(false)
			_set_hitbox_active(true)
			_phase = Phase.ACTIVE
			_time_left = active * time_scale()
			_on_active()
		Phase.ACTIVE:
			_set_hitbox_active(false)
			_phase = Phase.RECOVERY
			_time_left = recovery * time_scale()
		Phase.RECOVERY:
			enemy.damage.reset_poise()
			finished.emit(alert_state())


## Multiplies startup, active and recovery. Bosses speed up per phase.
func time_scale() -> float:
	return 1.0


## Runs once when the wind-up ends and the active window starts.
func _on_active() -> void:
	pass


func _set_hitbox_active(value: bool) -> void:
	if hitbox:
		hitbox.set_active(value)


func _on_parried(hurtbox: Hurtbox) -> void:
	enemy.damage.stun(hurtbox)


func _show_telegraph(shown: bool) -> void:
	if telegraph:
		telegraph.visible = shown
