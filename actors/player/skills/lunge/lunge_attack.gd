class_name PlayerLungeAttack
extends Node
## The lunge skill line (`lunge_1` to `lunge_3`).
##
## Attack pressed during a dash turns it into a Lunge: a thrust that drives
## forward along the ground and hits every enemy it passes. Contact damage
## doesn't stop it. Each level is faster, lasts longer and hits harder;
## the values per level are in the arrays below (index 0 is level 1).

@export var speeds: PackedFloat32Array = [260.0, 320.0, 380.0]
@export var durations: PackedFloat32Array = [0.25, 0.32, 0.4]
@export var damages: PackedInt32Array = [2, 3, 5]

@onready var player := owner as Player


func level() -> int:
	return player.skills.level(&"lunge")


func wants() -> bool:
	return level() > 0 and player.wants_attack()


func speed() -> float:
	return speeds[level() - 1]


func duration() -> float:
	return durations[level() - 1]


func damage() -> int:
	return damages[level() - 1]
