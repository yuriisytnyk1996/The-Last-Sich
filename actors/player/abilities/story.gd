class_name PlayerStory
extends Node
## Story flags: named facts about what the player has done in the world
## ("kobzar_met", "kobzar_done"). Conversations set them and NPCs, choices
## and other room objects read them (see `StoryCondition`). A quest's
## stage is simply which of its flags are set.
##
## Numbered flags ("rescued_01", "rescued_02"...) make a set that can be
## counted with `count_prefix()`, for quests about finding N of something.
## Counters hold numbers that only grow: currency donated, letters handed
## in (`add_counter()`, `counter()`).
##
## Every change is announced through `Events.story_changed`, so NPCs can
## appear or leave without a reference to the player. A global save
## system (see `SaveManager`).

var save_id := &"story"
var _flags: Array[StringName] = []
var _counters: Dictionary[StringName, int] = {}


func _ready() -> void:
	SaveManager.register(self)


func has(flag: StringName) -> bool:
	return flag in _flags


func set_flag(flag: StringName) -> void:
	if flag == &"" or has(flag):
		return
	_flags.append(flag)
	Events.story_changed.emit(flag)


func clear_flag(flag: StringName) -> void:
	if has(flag):
		_flags.erase(flag)
		Events.story_changed.emit(flag)


## How many set flags start with `prefix`.
func count_prefix(prefix: String) -> int:
	return _flags.filter(func(flag: StringName) -> bool: return flag.begins_with(prefix)).size()


func counter(counter_name: StringName) -> int:
	return _counters.get(counter_name, 0)


func add_counter(counter_name: StringName, amount: int) -> void:
	if counter_name == &"" or amount == 0:
		return
	_counters[counter_name] = counter(counter_name) + amount
	Events.story_changed.emit(counter_name)


func get_save_data() -> Dictionary:
	return {"flags": _flags.duplicate(), "counters": _counters.duplicate()}


func apply_save_data(data: Dictionary) -> void:
	_flags.clear()
	var saved: Variant = data.get("flags", [])
	if saved is Array:
		for flag: Variant in saved:
			_flags.append(StringName(str(flag)))
	_counters.clear()
	var counters: Variant = data.get("counters", {})
	if counters is Dictionary:
		for key: Variant in counters:
			_counters[StringName(str(key))] = int(counters[key])
	Events.story_changed.emit(&"")
