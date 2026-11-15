class_name PlayerFlasks
extends Node
## Healing flasks: a few charges that each restore some health.
##
## The Heal state drinks one. Rest points and respawning refill them all.
## Every change is reported through `Events.player_flasks_changed`, which
## drives the HUD.

## How many flasks the player carries when all are full.
@export var max_flasks := 2
## Health restored by one flask.
@export var heal_amount := 2
## Seconds the player stands still while drinking.
@export var drink_time := 0.5

var current := 0

@onready var player := owner as Player


func _ready() -> void:
	current = max_flasks
	# Deferred: the HUD may come after the player in the tree and isn't ready yet.
	_announce.call_deferred()


## Heal was pressed with a flask left and health missing. A flask is never
## wasted at full health, and a jump pressed in the same frame wins.
## Pressing with none left tells the HUD (`Events.player_flasks_empty`).
func wants() -> bool:
	if not Input.is_action_just_pressed("heal") or Input.is_action_just_pressed("jump"):
		return false
	if current <= 0:
		Events.player_flasks_empty.emit()
		return false
	return player.health.current < player.health.max_health


## Uses up one flask and heals right away.
func drink() -> void:
	if current <= 0:
		return
	current -= 1
	player.health.heal(heal_amount)
	_announce()


func refill() -> void:
	current = max_flasks
	_announce()


func _announce() -> void:
	Events.player_flasks_changed.emit(current, max_flasks)
