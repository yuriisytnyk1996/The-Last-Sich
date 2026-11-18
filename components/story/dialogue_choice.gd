class_name DialogueChoice
extends Resource
## One answer on the last line of a `Dialogue`. Picking it applies its
## `outcome`, then goes on to `next` or ends the conversation.
##
## Hidden while `condition` doesn't hold. Shown but greyed out while the
## player can't pay for its outcome (an item to hand over, a price).

@export var text := ""
@export var outcome: StoryOutcome
## The conversation that follows. Empty: the conversation ends.
@export var next: Dialogue
## When it is offered at all. Empty: always.
@export var condition: StoryCondition


func can_pick(player: Player) -> bool:
	return outcome == null or outcome.can_apply(player)


## The button text, with the price when there is one.
func label() -> String:
	if outcome and outcome.cost > 0:
		return "%s (%d)" % [text, outcome.cost]
	return text
