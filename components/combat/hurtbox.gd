class_name Hurtbox
extends Area2D
## The vulnerable part of an actor. Detects Hitboxes and reports hits.
##
## Set the collision mask to the attack layer that should hurt this actor
## (for example `player_attacks` for enemies). If `health` is set, damage is
## applied automatically (`Health.take_hit()`); the owner listens to `hurt` for everything else
## (knockback, flashing, sounds).

signal hurt(hitbox: Hitbox)
## A `parryable` hitbox arrived while `parrying` was on. No damage taken.
signal parried(hitbox: Hitbox)
## `guard` turned the hit away (a raised shield). No damage taken.
signal blocked(hitbox: Hitbox)
## A hit that `can_guard_slide()` arrived while `parrying` was on. No
## damage taken; the owner slides back.
signal guard_slid(hitbox: Hitbox)

@export var health: Health
## Seconds of immunity after a hit. 0 means every new hit counts.
@export var invincibility_time := 0.0
## Off for props (crates, cracked walls): hits on them don't reward the
## attacker, so they fill no spirit.
@export var rewards_attacker := true

## While on, `parryable` hitboxes are deflected instead of landing, even
## during invincibility. Other hitboxes hit as usual.
var parrying := false
## While on, `continuous` hitboxes (contact damage) pass through without a
## hit, so a lunge can run through an enemy. Turning it off checks the
## ones still overlapping.
var ignore_continuous := false:
	set(value):
		var was := ignore_continuous
		ignore_continuous = value
		if was and not value and not is_invincible():
			_recheck_continuous_hitboxes.call_deferred()

## Debug: while on, every hit is ignored, parryable or not (the console's
## `god` command). Pits still kill, they don't go through hitboxes.
var immune := false
## Optional check run before a hit lands: called with the Hitbox, returns
## true to block it. Set by the owner, for example a raised shield.
var guard := Callable()

var _invincible_left := 0.0
## Sources warding this hurtbox (`set_ward()`), such as a duma's warding
## circle. While any is set every hit is blocked.
var _wards: Dictionary[StringName, bool] = {}


func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _invincible_left <= 0.0:
		return
	_invincible_left = maxf(_invincible_left - delta, 0.0)
	# Not while turned off (a dead or dormant enemy).
	if _invincible_left == 0.0 and monitoring:
		_recheck_continuous_hitboxes()


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Replaces the remaining invincibility. INF holds it until set again.
func set_invincible_for(seconds: float) -> void:
	_invincible_left = maxf(seconds, 0.0)


## Ends invincibility early, for example on respawn.
func clear_invincibility() -> void:
	_invincible_left = 0.0


## Turns a ward from `source` on or off. While any ward is on, every hit
## that isn't parried or guard-slid is blocked (`blocked`), invincible or
## not. Pits and spikes still kill: they don't go through hitboxes. When
## the last ward ends, contact damage still overlapping hits again.
func set_ward(source: StringName, on: bool) -> void:
	var was := is_warded()
	if on:
		_wards[source] = true
	else:
		_wards.erase(source)
	if was and not is_warded() and not is_invincible():
		_recheck_continuous_hitboxes.call_deferred()


func is_warded() -> bool:
	return not _wards.is_empty()


## A continuous hitbox (spikes) we are still standing in hits again.
func _recheck_continuous_hitboxes() -> void:
	for area in get_overlapping_areas():
		var hitbox := area as Hitbox
		if hitbox and hitbox.continuous:
			_on_area_entered(hitbox)
			return


func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null or immune or (health and health.is_dead()):
		return
	if parrying and hitbox.parryable:
		parried.emit(hitbox)
		hitbox.register_parry(self)
		return
	if parrying and hitbox.can_guard_slide():
		guard_slid.emit(hitbox)
		hitbox.register_guard_slide(self)
		return
	if is_invincible() or (ignore_continuous and hitbox.continuous):
		return
	if is_warded() or (guard.is_valid() and guard.call(hitbox)):
		blocked.emit(hitbox)
		hitbox.register_block(self)
		return

	_invincible_left = invincibility_time
	hitbox.roll_critical()
	hurt.emit(hitbox)
	hitbox.register_hit(self)
	if health:
		health.take_hit(hitbox)
