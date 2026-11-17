class_name PlayerDumas
extends Node
## Dumas: songs worn in the one duma slot and sung with the duma button
## for spirit. See the Duma state for the cast itself.
##
## A press while standing or running starts the cast when a duma is worn,
## none is running and there is enough spirit (`cost()`). Otherwise
## `Events.spirit_short` flashes the HUD. The spirit is spent at the cast
## point (`begin()`), where the duma's ON_USE effects start. While any of
## them lasts the duma is running (`is_running()`): no other can be sung,
## and `Events.duma_time_changed` reports the time left. Dying or
## entering another room ends it (the `World` calls `end()`). Resting
## doesn't.

## Goes up each time `end()` cuts dumas short. Delayed attacks (a row of
## pillars, a volley) note it when sung and are dropped if it changed.
var generation := 0
## The duma being sung or running. Null when none is.
var _item: Item
var _time_left := 0.0
var _total := 0.0

@onready var player := owner as Player


func _ready() -> void:
	await owner.ready
	player.health.died.connect(end)


func _physics_process(delta: float) -> void:
	if _total <= 0.0:
		return
	_time_left = maxf(_time_left - delta, 0.0)
	Events.duma_time_changed.emit(_time_left / _total)
	if _time_left <= 0.0:
		_finish()


## The duma worn, or null.
func equipped() -> Item:
	var worn := player.inventory.worn_of(Item.Kind.DUMA)
	return worn[0] if not worn.is_empty() else null


## Spirit the worn duma costs, with `PlayerStats.DUMA_COST`.
func cost() -> float:
	var item := equipped()
	if item == null:
		return 0.0
	return maxf(item.spirit_cost + player.stats.get_value(PlayerStats.DUMA_COST), 0.0)


## Multiplier for the damage of duma attacks.
func strength() -> float:
	return player.stats.get_value(PlayerStats.DUMA_STRENGTH)


func is_running() -> bool:
	return _total > 0.0


## The duma button was just pressed and a duma can be sung. Flashes the
## spirit bar when it can't for lack of spirit or of a duma.
func wants() -> bool:
	if not Input.is_action_just_pressed("duma") or is_running():
		return false
	if equipped() != null and player.spirit.current >= cost():
		return true
	Events.spirit_short.emit()
	return false


## The cast point: pays the spirit and starts the worn duma's effects.
## Returns false, doing nothing, when the spirit is no longer there.
func begin() -> bool:
	var item := equipped()
	if item == null or not player.spirit.spend(cost()):
		return false
	_item = item
	var extra := player.stats.get_value(PlayerStats.DUMA_DURATION)
	_total = player.item_effects.use(item, extra)
	_time_left = _total
	if _total > 0.0:
		Events.duma_time_changed.emit(1.0)
	else:
		_item = null
	return true


## Ends the running duma at once: on death and on entering a room.
func end() -> void:
	generation += 1
	if _item:
		player.item_effects.end_use(_item)
	_finish()


func _finish() -> void:
	_item = null
	_total = 0.0
	_time_left = 0.0
	Events.duma_time_changed.emit(0.0)
