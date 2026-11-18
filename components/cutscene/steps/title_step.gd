class_name TitleStep
extends CutsceneStep
## Shows a title card in the middle of the screen (`TitleCard`): a zone's
## name as the player arrives, a boss's name as it rises. The step lasts
## as long as the card; with `wait` off the cutscene goes on under it.

@export var title := ""
@export var subtitle := ""
## Seconds fully shown.
@export var hold := 2.0
## Seconds to fade in, and again to fade out.
@export var fade := 0.5


func play(run: CutsceneRun) -> void:
	Events.title_card_shown.emit(title, subtitle, hold, fade)
	await run.wait(hold + fade * 2.0)
