class_name StoryAutosave
extends Node
## Saves the game as soon as the story changes (`Events.story_changed`),
## so quitting before the next rest can't undo a quest step, a hand-in or
## its reward. The save waits until the end of the frame, so an outcome
## that changes several flags and counters writes once.
##
## A child of the `World`. An empty flag means a save was just loaded,
## which has nothing new to write.

var _queued := false

@onready var world := owner as World


func _ready() -> void:
	Events.story_changed.connect(_on_story_changed)


func _on_story_changed(flag: StringName) -> void:
	if flag != &"" and not _queued:
		_queued = true
		_save.call_deferred()


func _save() -> void:
	_queued = false
	if is_instance_valid(world.room):
		SaveManager.save_game(world.room)
