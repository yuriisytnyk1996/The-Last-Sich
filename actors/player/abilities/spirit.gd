class_name PlayerSpirit
extends Node
## Spirit: a resource the player fills by landing hits and spends on
## skills such as the ranged attack.
##
## Every hit an attack lands adds `per_hit`, multiplied for heavy hits.
## Death marks lower both the maximum (`max_factor`) and the gain
## (`gain_factor`), see `DeathPenalty`. Spirit starts empty on every load
## and resting doesn't refill it: it is earned in fights. Every change is
## reported through `Events.player_spirit_changed`, which drives the HUD.

## Maximum spirit without death marks.
@export var full_max := 30.0
## Spirit gained per landed hit.
@export var per_hit := 2.0
## Multiplier for hits with a HEAVY reaction (the riposte).
@export var heavy_multiplier := 2.0

## Part of `full_max` available, set by `DeathPenalty`.
var max_factor := 1.0:
	set(value):
		max_factor = clampf(value, 0.0, 1.0)
		current = minf(current, get_max())
		_announce()
## Multiplier for spirit gained from hits, set by `DeathPenalty`.
var gain_factor := 1.0
var current := 0.0

@onready var player := owner as Player


func _ready() -> void:
	for hitbox in player.find_children("*", "Hitbox"):
		(hitbox as Hitbox).hit_landed.connect(_on_hit_landed.bind(hitbox))
	# Deferred: the HUD may come after the player in the tree and isn't ready yet.
	_announce.call_deferred()


func get_max() -> float:
	return full_max * max_factor


## Adds spirit, never past the current maximum. Not scaled by `gain_factor`.
func add(amount: float) -> void:
	if amount <= 0.0:
		return
	current = minf(current + amount, get_max())
	_announce()


## Takes `amount` away if there is enough. Returns false and changes
## nothing otherwise.
func spend(amount: float) -> bool:
	if amount < 0.0 or amount > current:
		return false
	current -= amount
	_announce()
	return true


func _on_hit_landed(hurtbox: Hurtbox, hitbox: Hitbox) -> void:
	if not hurtbox.rewards_attacker:
		return
	var amount := per_hit * gain_factor
	if hitbox.reaction == Hitbox.Reaction.HEAVY:
		amount *= heavy_multiplier
	add(amount)


func _announce() -> void:
	Events.player_spirit_changed.emit(current, get_max(), full_max)
