class_name StoryCondition
extends Resource
## A check on the player's story so far: flags (`PlayerStory`) and items.
## Every part that is set must hold; empty parts are ignored, so an empty
## condition always holds.
##
## Used wherever the world depends on a quest: which conversation an NPC
## starts (`Dialogue.condition`), which answers are offered
## (`DialogueChoice.condition`) and whether an NPC is there at all
## (`Npc.presence`).

## Every one of these flags must be set.
@export var all_flags: Array[StringName] = []
## None of these flags may be set.
@export var no_flags: Array[StringName] = []
## The player must carry every one of these now.
@export var owns: Array[Item] = []
## The player must not carry any of these now.
@export var lacks: Array[Item] = []
## The player must carry at least one of these now (something to turn in).
@export var owns_any: Array[Item] = []
## The player must have had every one of these at some point, even if it
## was handed over since.
@export var obtained: Array[Item] = []
## A counted set: at least `count_at_least` flags starting with
## `count_prefix` must be set ("rescued_" for "rescued_01"...).
@export var count_prefix := ""
@export var count_at_least := 0
## A `PlayerStory` counter must be at least `counter_at_least`.
@export var counter := &""
@export var counter_at_least := 0


func is_met(player: Player) -> bool:
	return _story_holds(player.story) and _items_hold(player.inventory)


func _story_holds(story: PlayerStory) -> bool:
	if all_flags.any(func(flag: StringName) -> bool: return not story.has(flag)):
		return false
	if no_flags.any(story.has):
		return false
	if counter != &"" and story.counter(counter) < counter_at_least:
		return false
	return count_prefix == "" or story.count_prefix(count_prefix) >= count_at_least


func _items_hold(inventory: PlayerInventory) -> bool:
	if not owns.all(inventory.owns) or lacks.any(inventory.owns):
		return false
	if not obtained.all(inventory.has_obtained):
		return false
	return owns_any.is_empty() or owns_any.any(inventory.owns)


## True for a missing condition too, so `StoryCondition.holds(x, player)`
## reads well for optional exports.
static func holds(condition: StoryCondition, player: Player) -> bool:
	return condition == null or condition.is_met(player)
