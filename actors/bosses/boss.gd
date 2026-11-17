class_name Boss
extends Enemy
## Base for every boss: an `Enemy` that waits in `Dormant` until its
## `BossArena` wakes it, fights in phases and never patrols.
##
## Phases start when health drops to a threshold. The change waits until
## the current attack or stun is over, then the boss roars (`Roar` state)
## and moves on with faster timings (`phase_time_scales`).
## Its `Damage` node should have `flinches` and `stays_dead` off.

signal phase_changed(phase: int)

## Shown on the boss bar.
@export var display_name := "Boss"
## Health fractions (0 to 1) where the next phase starts, highest first.
@export var phase_thresholds: Array[float] = [0.5]
## Attack timing multiplier per phase. Below 1 is faster.
@export var phase_time_scales: Array[float] = [1.0, 0.8]

## 0 for the first phase.
var phase := 0
var awake := false
var _reached_phase := 0


func _ready() -> void:
	super()
	health.health_changed.connect(_on_health_changed)


## Starts the fight: a roar, then the first attack.
func awaken() -> void:
	awake = true
	state_machine.transition_to(BossState.ROAR)


func reset() -> void:
	awake = false
	phase = 0
	_reached_phase = 0
	super()


func home_state() -> StringName:
	return BossState.DORMANT


func alert_state() -> StringName:
	return BossState.ROAR if has_pending_phase() else BossState.DECIDE


## Health crossed a threshold and the new phase hasn't started yet.
func has_pending_phase() -> bool:
	return _reached_phase > phase and not health.is_dead()


## Moves on to the phase health has reached. Called by the Roar state.
func enter_pending_phase() -> void:
	if not has_pending_phase():
		return
	phase = _reached_phase
	phase_changed.emit(phase)


## The attack timing multiplier for the current phase.
func time_scale() -> float:
	if phase_time_scales.is_empty():
		return 1.0
	return phase_time_scales[mini(phase, phase_time_scales.size() - 1)]


## Horizontal distance to the player (px), or INF without a live target.
func distance_to_target() -> float:
	return absf(_target_offset().x) if _has_live_target() else INF


func _on_health_changed(current: int, maximum: int) -> void:
	var fraction := float(current) / float(maxi(maximum, 1))
	var reached := 0
	for threshold in phase_thresholds:
		if fraction <= threshold:
			reached += 1
	_reached_phase = maxi(_reached_phase, reached)
	if awake:
		Events.boss_health_changed.emit(current, maximum)
