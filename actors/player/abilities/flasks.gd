class_name PlayerFlasks
extends Node
## Healing flasks: a few charges that each restore some health.
##
## The Heal state drinks one. Rest points and respawning refill them all.
## How many there are and how much one heals are the player's stats
## (`PlayerStats.FLASK_COUNT`, `FLASK_HEAL`). Every change is reported
## through `Events.player_flasks_changed`, which drives the HUD.

## Seconds the player stands still while drinking.
@export var drink_time := 0.5

var current := 0

@onready var player := owner as Player


func _ready() -> void:
	await owner.ready
	current = max_flasks()
	player.stats.stat_changed.connect(_on_stat_changed)
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


## Flasks carried when all are full.
func max_flasks() -> int:
	return roundi(player.stats.get_value(PlayerStats.FLASK_COUNT))


## Health restored by one flask.
func heal_amount() -> int:
	return roundi(player.stats.get_value(PlayerStats.FLASK_HEAL))


## Uses up one flask and heals right away.
func drink() -> void:
	if current <= 0:
		return
	current -= 1
	player.health.heal(heal_amount())
	_announce()


func refill() -> void:
	current = max_flasks()
	_announce()


## A lower count takes the extra flasks away; a higher one adds empty
## slots that the next refill fills.
func _on_stat_changed(stat: StringName) -> void:
	if stat != PlayerStats.FLASK_COUNT:
		return
	current = mini(current, max_flasks())
	_announce()


func _announce() -> void:
	Events.player_flasks_changed.emit(current, max_flasks())
