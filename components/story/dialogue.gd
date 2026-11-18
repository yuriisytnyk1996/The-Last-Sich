class_name Dialogue
extends Resource
## One conversation: lines read one after another, then either the end or
## a set of answers (`choices`) on the last line. Each `.tres` file is one
## conversation; an NPC lists several and starts the first whose
## `condition` holds (see `Npc`). Shown by a `DialogueScreen`.
##
## `outcome` runs once every line has been read, before any answers are
## shown: "met the kobzar" is set even if the player then walks off.

## Who speaks. Empty: the NPC's own name.
@export var speaker := ""
## One entry per text box.
@export_multiline var lines: PackedStringArray = []
## Answers offered on the last line. Empty: the conversation just ends.
@export var choices: Array[DialogueChoice] = []
## Applied after the last line.
@export var outcome: StoryOutcome
## When an NPC may start this one. Empty: always.
@export var condition: StoryCondition


## The answers the player may see now, in order.
func choices_for(player: Player) -> Array[DialogueChoice]:
	return choices.filter(
		func(choice: DialogueChoice) -> bool: return StoryCondition.holds(choice.condition, player)
	)
