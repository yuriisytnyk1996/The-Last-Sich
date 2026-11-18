class_name StoryStep
extends CutsceneStep
## Applies a `StoryOutcome` in the middle of a cutscene: set a flag that a
## `StoryToggle` reacts to at once, give a reward, show a message.
## Skipped before it ran: applied then.

@export var outcome: StoryOutcome


func play(run: CutsceneRun) -> void:
	outcome.apply(run.player)


func skip(run: CutsceneRun) -> void:
	outcome.apply(run.player)
