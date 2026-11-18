class_name PlayClock
extends Node
## Counts the time played in this save slot (global save system
## "play_clock"). It stops while the tree is paused, so menus and room
## transitions don't count. Shown on the slot-select screen.

var save_id := &"play_clock"
## Seconds played in this slot, across sessions.
var seconds := 0.0


func _ready() -> void:
	SaveManager.register(self)


func _process(delta: float) -> void:
	seconds += delta


func get_save_data() -> Dictionary:
	return {"seconds": seconds}


func apply_save_data(data: Dictionary) -> void:
	seconds = maxf(float(data.get("seconds", 0.0)), 0.0)
