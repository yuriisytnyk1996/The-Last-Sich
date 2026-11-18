class_name EmptyFlask
extends InteractionArea
## An empty flask lying in a room. Pressing interact here gives the player
## one more flask for good (`PlayerUpgrades.upgrade(FLASKS)`). It comes
## empty: the next rest point or respawn fills it.
##
## Taken once: the room saves that through the `persistent` group, so it
## stays gone.

var _taken := false


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)


func _activate(player: Node2D) -> void:
	if _taken:
		return
	(player as Player).upgrades.upgrade(PlayerUpgrades.Kind.FLASKS)
	_take()


func get_save_data() -> Dictionary:
	return {"taken": _taken}


func apply_save_data(data: Dictionary) -> void:
	if data.get("taken", false):
		_take()


func _take() -> void:
	_taken = true
	hide()
	set_deferred(&"monitoring", false)
