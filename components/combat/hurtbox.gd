class_name Hurtbox
extends Area2D
## The vulnerable part of an actor. Detects Hitboxes and reports hits.
##
## Set the collision mask to the attack layer that should hurt this actor
## (for example `player_attacks` for enemies). If `health` is set, damage is
## applied automatically; the owner listens to `hurt` for everything else
## (knockback, flashing, sounds).

signal hurt(hitbox: Hitbox)
## A `parryable` hitbox arrived while `parrying` was on. No damage taken.
signal parried(hitbox: Hitbox)

@export var health: Health
## Seconds of immunity after a hit. 0 means every new hit counts.
@export var invincibility_time := 0.0

## While on, `parryable` hitboxes are deflected instead of landing, even
## during invincibility. Other hitboxes hit as usual.
var parrying := false

var _invincible_left := 0.0


func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _invincible_left <= 0.0:
		return
	_invincible_left = maxf(_invincible_left - delta, 0.0)
	if _invincible_left == 0.0:
		_recheck_continuous_hitboxes()


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Replaces the remaining invincibility. INF holds it until set again.
func set_invincible_for(seconds: float) -> void:
	_invincible_left = maxf(seconds, 0.0)


## Ends invincibility early, for example on respawn.
func clear_invincibility() -> void:
	_invincible_left = 0.0


## A continuous hitbox (spikes) we are still standing in hits again.
func _recheck_continuous_hitboxes() -> void:
	for area in get_overlapping_areas():
		var hitbox := area as Hitbox
		if hitbox and hitbox.continuous:
			_on_area_entered(hitbox)
			return


func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null or (health and health.is_dead()):
		return
	if parrying and hitbox.parryable:
		parried.emit(hitbox)
		hitbox.register_parry(self)
		return
	if is_invincible():
		return

	_invincible_left = invincibility_time
	hurt.emit(hitbox)
	hitbox.register_hit(self)
	if health:
		health.take_damage(hitbox.damage)
