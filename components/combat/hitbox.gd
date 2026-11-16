class_name Hitbox
extends Area2D
## The damaging part of an attack or hazard.
##
## A hitbox does no detection itself: Hurtboxes detect it. Turning it off
## disables its collision shapes, so turning it on again counts as a new hit
## on everything it overlaps. While inactive it is also hidden, so a child
## placeholder graphic shows exactly when the hitbox is live.

## Emitted when a Hurtbox accepts a hit from this hitbox.
signal hit_landed(hurtbox: Hurtbox)
## Emitted when a parrying Hurtbox deflects this hitbox. The attacker
## listens to this to get stunned.
signal parried(hurtbox: Hurtbox)

## How hard the receiver reacts. LIGHT: damage and flash, no knockback or
## stagger. NORMAL: stagger and knockback. HEAVY: longer stagger, more
## knockback, stronger hit-stop and shake.
enum Reaction { NORMAL, LIGHT, HEAVY }
## What kind of harm the hit does. The receiver's `Stats` can resist each
## element separately (see `RESIST_STATS`).
enum Element { NORMAL, CONTACT, FIRE, POISON }

const FEEDBACK_SCALE: Dictionary[Reaction, float] = {
	Reaction.LIGHT: 0.5,
	Reaction.NORMAL: 1.0,
	Reaction.HEAVY: 2.0,
}
const RESIST_STATS: Dictionary[Element, StringName] = {
	Element.NORMAL: Stats.NORMAL_RESIST,
	Element.CONTACT: Stats.CONTACT_RESIST,
	Element.FIRE: Stats.FIRE_RESIST,
	Element.POISON: Stats.POISON_RESIST,
}

## Base damage, before the attacker's `Stats.DAMAGE` multiplier.
@export var damage := 20
@export var element := Element.NORMAL
@export var knockback_force := 120.0
## Direction when the hitbox faces right. Mirrored when a parent is flipped
## with a negative scale.x.
@export var knockback_direction := Vector2.RIGHT
@export var reaction := Reaction.NORMAL
@export var active_on_start := false
## Keeps hurting a hurtbox that stays inside it, each time that hurtbox's
## invincibility ends. For hazards and contact damage, not for swings.
@export var continuous := false
## A parrying hurtbox can deflect this hit. For telegraphed melee swings,
## not for contact damage, hazards or projectiles.
@export var parryable := false

## Stats of whoever deals this hit. Their `Stats.DAMAGE` scales `damage`.
## Optional: without it the base damage is dealt.
var attacker_stats: Stats

var _active := false
var _has_hit := false


func _ready() -> void:
	monitoring = false
	set_active(active_on_start)


func set_active(value: bool) -> void:
	_active = value
	visible = value
	if value:
		_has_hit = false
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			# Deferred: shapes can't change during a physics callback.
			child.set_deferred(&"disabled", not value)


func is_active() -> bool:
	return _active


## True if this activation has hit anything yet.
func has_hit() -> bool:
	return _has_hit


## Called by the Hurtbox that accepted the hit.
func register_hit(hurtbox: Hurtbox) -> void:
	_has_hit = true
	hit_landed.emit(hurtbox)


## Called by the Hurtbox that parried this hit. No damage is dealt.
func register_parry(hurtbox: Hurtbox) -> void:
	parried.emit(hurtbox)


## Damage this hit deals before the receiver's resistance. Rounded, and
## never below 1 unless the scaled damage is 0.
func get_damage() -> int:
	var scaled := float(damage)
	if attacker_stats:
		scaled *= attacker_stats.get_value(Stats.DAMAGE, 1.0)
	if scaled <= 0.0:
		return 0
	return maxi(roundi(scaled), 1)


## Multiplier for hit-stop and camera shake, from `reaction`.
func feedback_scale() -> float:
	return FEEDBACK_SCALE[reaction]


func get_knockback() -> Vector2:
	var direction := knockback_direction.normalized()
	if global_transform.x.x < 0.0:
		direction.x = -direction.x
	return direction * knockback_force


## Which way this hit pushes something standing at `target`: 1 right,
## -1 left, 0 if it can't tell. Follows the knockback; a hitbox that pushes
## straight up or down (spikes, up slashes) pushes away from its centre.
func push_direction(target: Vector2) -> float:
	var direction := signf(get_knockback().x)
	if direction == 0.0:
		direction = signf(target.x - global_position.x)
	return direction
