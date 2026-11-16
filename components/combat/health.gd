class_name Health
extends Node
## Hit points for anything that can be damaged.
##
## Knows nothing about who owns it. The owner listens to `health_changed`
## and `died` and decides what they mean (flash, play a sound, respawn...).
## With `stats` set, the maximum is `Stats.MAX_HEALTH` and follows its
## changes, and hits are reduced by the stats' resistances.

signal health_changed(current: int, maximum: int)
signal died

## Used when `stats` is not set.
@export var max_health := 100
@export var stats: Stats

var current := 0


func _ready() -> void:
	if stats:
		max_health = _max_from_stats()
		stats.stat_changed.connect(_on_stat_changed)
	current = max_health


## Damage from a hit, after this actor's resistance to its element.
## A resistance below 1 always lets at least 1 damage through.
func take_hit(hitbox: Hitbox) -> void:
	var amount := hitbox.get_damage()
	if stats and amount > 0:
		var resist := stats.get_value(Hitbox.RESIST_STATS[hitbox.element])
		amount = 0 if resist >= 1.0 else maxi(roundi(amount * (1.0 - resist)), 1)
	take_damage(amount)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	current = maxi(current - amount, 0)
	health_changed.emit(current, max_health)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	current = mini(current + amount, max_health)
	health_changed.emit(current, max_health)


## Instant death that ignores the amount left (bottomless pits).
func kill() -> void:
	if is_dead():
		return
	take_damage(current)


## Back to full health, also after dying.
func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func is_dead() -> bool:
	return current == 0


func _max_from_stats() -> int:
	return maxi(roundi(stats.get_value(Stats.MAX_HEALTH, max_health)), 1)


## A higher maximum leaves current health as it is; a lower one cuts it.
func _on_stat_changed(stat: StringName) -> void:
	if stat != Stats.MAX_HEALTH or is_dead():
		return
	max_health = _max_from_stats()
	current = mini(current, max_health)
	health_changed.emit(current, max_health)
