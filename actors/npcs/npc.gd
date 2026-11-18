class_name Npc
extends InteractionArea
## Someone the player can talk to. Pressing interact next to them starts
## the first of their `dialogues` whose condition holds, in a
## `DialogueScreen` that pauses the game. Order the list from the most
## specific (quest done, item brought) to the plainest (first meeting),
## which usually has no condition.
##
## With a `presence` condition the NPC is only there while it holds: they
## arrive once a quest starts, or leave once it is done. They check again
## on every `Events.story_changed`. Nothing to save: the flags they read
## live in `PlayerStory`.
##
## Each NPC is a scene inheriting `npc.tscn` in its own folder, with its
## conversations as `.tres` files next to it. Put them in a room's `Logic`.

## Shown as the speaker unless a conversation names another one.
@export var display_name := ""
@export var dialogues: Array[Dialogue] = []
## When the NPC is in the room at all. Empty: always.
@export var presence: StoryCondition

@onready var visual: Node2D = $Visual


func _ready() -> void:
	super()
	Events.story_changed.connect(_on_story_changed)
	# Deferred: the player may still be loading its flags this frame.
	_refresh.call_deferred()


## The conversation talking now would start, or null.
func current_dialogue(player: Player) -> Dialogue:
	for dialogue in dialogues:
		if StoryCondition.holds(dialogue.condition, player):
			return dialogue
	return null


func is_present() -> bool:
	return visible


func _activate(body: Node2D) -> void:
	var player := body as Player
	var dialogue := current_dialogue(player)
	if not is_present() or dialogue == null:
		return
	player.velocity.x = 0.0
	player.set_facing(global_position.x - player.global_position.x)
	visual.scale.x = 1.0 if player.global_position.x >= global_position.x else -1.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(DialogueScreen.new(dialogue, player, display_name))


func _on_story_changed(_flag: StringName) -> void:
	_refresh()


func _refresh() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var here := player == null or StoryCondition.holds(presence, player)
	visible = here
	set_deferred(&"monitoring", here)
	if not here:
		_on_body_exited(player)
