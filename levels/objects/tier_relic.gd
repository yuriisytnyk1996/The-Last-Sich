class_name TierRelic
extends InteractionArea
## A relic that opens the next skill tier when the player touches it
## (`PlayerSkills.raise_tier()`). It is taken once: the room saves that
## through the `persistent` group, so it stays gone.

var _taken := false


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)


func _activate(player: Node2D) -> void:
	if _taken:
		return
	(player as Player).skills.raise_tier()
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
