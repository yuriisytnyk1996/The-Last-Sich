class_name StoryOutcome
extends Resource
## What happens to the player's story when a conversation ends, an answer
## is picked or a `StoryTrigger` fires: flags set or cleared, a counter
## raised, items handed over or given, currency paid or received, a short
## message shown, a "how to play" tip shown the first time. `apply()` does all of it at once.
##
## An outcome that asks for something (`take_items`, `cost`) can only be
## applied while the player has it; the answer offering it is shown but
## can't be picked until then (`can_apply()`).

@export var set_flags: Array[StringName] = []
@export var clear_flags: Array[StringName] = []
## Taken from the player (quest items handed over).
@export var take_items: Array[Item] = []
## Currency the player pays.
@export var cost := 0
## Given to the player (rewards).
@export var give_items: Array[Item] = []
## Currency the player receives.
@export var reward := 0
## Every one of these the player carries is taken, and `counter` goes up
## by one for each: "hand over all the letters you found".
@export var turn_in: Array[Item] = []
## The `PlayerStory` counter raised by `counter_add` and by `turn_in`.
@export var counter := &""
@export var counter_add := 0
## Shown at the bottom of the screen, like a found item ("A captive is free").
@export var message := ""
## Shown as a card the first time (see `TipLog`): a scripted tip.
@export var tip: Tip


func can_apply(player: Player) -> bool:
	if player.wallet.amount < cost:
		return false
	for item in take_items:
		if not player.inventory.owns(item):
			return false
	return true


## Does nothing and returns false when the player lacks what it takes.
func apply(player: Player) -> bool:
	if not can_apply(player):
		return false
	if cost > 0:
		player.wallet.spend(cost)
	for item in take_items:
		player.inventory.remove(item)
	for item in give_items:
		player.inventory.add(item)
	if reward > 0:
		player.wallet.add(reward)
	var turned_in := 0
	for item in turn_in:
		if player.inventory.remove(item):
			turned_in += 1
	player.story.add_counter(counter, counter_add + turned_in)
	if message != "":
		Events.message_shown.emit(message)
	if tip:
		Events.tip_requested.emit(tip)
	for flag in clear_flags:
		player.story.clear_flag(flag)
	for flag in set_flags:
		player.story.set_flag(flag)
	return true
