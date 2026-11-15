class_name Health
extends Node
## Hit points for anything that can be damaged.
##
## Knows nothing about who owns it. The owner listens to `health_changed`
## and `died` and decides what they mean (flash, play a sound, respawn...).

signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 5

var current := 0


func _ready() -> void:
	current = max_health


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


## Back to full health, also after dying.
func reset() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func is_dead() -> bool:
	return current == 0
