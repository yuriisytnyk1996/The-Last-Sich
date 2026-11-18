class_name DialogueStep
extends CutsceneStep
## Plays a conversation in the usual text box, which pauses the game until
## it closes (the skip waits too). Its outcome and the answers' outcomes
## apply as when talking to an NPC. Skipped before it opened: only the
## conversation's own `outcome` applies, since no answer was picked.

@export var dialogue: Dialogue
## Shown as the speaker unless the conversation names one.
@export var speaker := ""


func play(run: CutsceneRun) -> void:
	var menu := PausingMenu.new()
	menu.free_on_close = true
	run.cutscene.add_child(menu)
	menu.open_screen(DialogueScreen.new(dialogue, run.player, speaker))
	await run.until(menu.closed)


func skip(run: CutsceneRun) -> void:
	if dialogue.outcome:
		dialogue.outcome.apply(run.player)
