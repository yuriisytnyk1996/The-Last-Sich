class_name ItemPickup
extends InteractionArea
## An item lying in a room. Pressing interact here gives it to the player
## (`PlayerInventory.add()`). It is taken once: the room saves that
## through the `persistent` group, so it stays gone.

## The player picked it up (never when a save restores it as gone).
signal taken

@export var item: Item

var _taken := false


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)


func _activate(player: Node2D) -> void:
	if _taken:
		return
	(player as Player).inventory.add(item)
	_take()
	taken.emit()


func get_save_data() -> Dictionary:
	return {"taken": _taken}


func apply_save_data(data: Dictionary) -> void:
	if data.get("taken", false):
		_take()


func _take() -> void:
	_taken = true
	hide()
	set_deferred(&"monitoring", false)
