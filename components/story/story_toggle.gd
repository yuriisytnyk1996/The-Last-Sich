class_name StoryToggle
extends Node
## Changes a room as the story moves on: shows or hides nodes, or opens or
## closes gates, by a `StoryCondition`. It checks when the room loads and
## on every `Events.story_changed`, so a chest can appear once a quest is
## done or a gate can open once a debt is paid.
##
## A hidden node is also switched off (`PROCESS_MODE_DISABLED`), which
## takes its collision shapes out of the world: a hidden chest can't be
## opened, a hidden platform can't be stood on. Saves nothing: the flags
## are the record.

## SHOW and HIDE set visibility (SHOW: shown while the condition holds).
## OPEN and CLOSE call `set_open()` (a `Gate`; OPEN: open while it holds).
enum Mode { SHOW, HIDE, OPEN, CLOSE }

@export var condition: StoryCondition
@export var mode := Mode.SHOW
## The nodes to change. Empty: the parent.
@export var targets: Array[Node] = []


func _ready() -> void:
	if targets.is_empty():
		targets = [get_parent()]
	Events.story_changed.connect(_on_story_changed)
	# Deferred: the player may still be loading its flags this frame.
	_refresh.call_deferred(true)


func _on_story_changed(_flag: StringName) -> void:
	_refresh(false)


## `instant` on room load: gates snap into place instead of moving.
func _refresh(instant: bool) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var holds := StoryCondition.holds(condition, player)
	for target in targets:
		match mode:
			Mode.SHOW, Mode.HIDE:
				_set_shown(target, holds == (mode == Mode.SHOW))
			Mode.OPEN, Mode.CLOSE:
				target.call(&"set_open", holds == (mode == Mode.OPEN), instant)


func _set_shown(target: Node, shown: bool) -> void:
	if target is CanvasItem:
		(target as CanvasItem).visible = shown
	target.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
