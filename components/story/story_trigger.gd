class_name StoryTrigger
extends Node
## Moves the story on when something happens in a room: applies `outcome`
## (and sets `flag`) whenever a signal of `source` fires. The source is the
## parent unless set. Signals with arguments work too; they are ignored.
##
## Examples: a `Breakable` cage's `broken` frees a captive ("freed_01"), a
## `BossArena`'s `boss_beaten` marks the boss as beaten, an `Area2D`'s
## `body_entered` (masking only the player) marks a place as visited, an
## `ItemPickup`'s `taken` starts a quest.
##
## Fires only while `condition` holds, so a quest can fail when something
## happens first ("boss beaten before the kobzar got his string"). Saves
## nothing itself: the flags it sets are the record. Sources that can fire
## again (an area) should use a condition with `no_flags` on their own flag
## when the outcome must not repeat.

## The node to watch. Empty: the parent.
@export var source: Node
@export var signal_name := &""
## Set when it fires, for the common case of one flag per placed object.
@export var flag := &""
@export var outcome: StoryOutcome
## Fires only while this holds. Empty: always.
@export var condition: StoryCondition


func _ready() -> void:
	var watched := source if source else get_parent()
	if not watched.has_signal(signal_name):
		push_error("StoryTrigger %s: %s has no signal %s" % [name, watched.name, signal_name])
		return
	var arguments := _argument_count(watched)
	watched.connect(signal_name, _fire.unbind(arguments) if arguments > 0 else _fire)


func _fire() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null or not StoryCondition.holds(condition, player):
		return
	if outcome:
		outcome.apply(player)
	player.story.set_flag(flag)


func _argument_count(watched: Node) -> int:
	for info in watched.get_signal_list():
		if info.name == signal_name:
			return info.args.size()
	return 0
