class_name PlayerUnlocks
extends Node
## Traversal abilities the player has unlocked, such as seeing hidden
## platforms. Level design gates places behind them.
##
## Unlocks come from items: an `UnlockEffect` grants one while it runs
## and revokes it when it stops. One unlock can be held by several
## sources and stays on while any of them holds it. Nothing here is
## saved: the inventory is, and loading it starts the effects again.
##
## Every change is announced through `Events.player_unlocks_changed`, so
## room objects (`RevealPlatform`) react without a reference to the player.

const REVEAL_PLATFORMS := &"reveal_platforms"
## Kneeling at a rest point offers travel to any other one found.
const REST_TRAVEL := &"rest_travel"
## Resting fills spirit, and so does respawning after death.
const REST_SPIRIT := &"rest_spirit"
## A long fall lands like a short one: no hard landing.
const SOFT_LANDING := &"soft_landing"

## unlock -> the sources that hold it.
var _sources: Dictionary[StringName, Array] = {}


func has(unlock: StringName) -> bool:
	return _sources.has(unlock)


func grant(unlock: StringName, source: StringName) -> void:
	var held: Array = _sources.get_or_add(unlock, [])
	if source in held:
		return
	held.append(source)
	if held.size() == 1:
		Events.player_unlocks_changed.emit()


func revoke(unlock: StringName, source: StringName) -> void:
	if not _sources.has(unlock):
		return
	_sources[unlock].erase(source)
	if _sources[unlock].is_empty():
		_sources.erase(unlock)
		Events.player_unlocks_changed.emit()
