class_name FadeStep
extends CutsceneStep
## Fades the screen to black, or back from it. A cutscene that fades out
## must fade back in before it ends; a skip fades back in on its own.

## On: to black. Off: back to the game.
@export var to_black := true
## Seconds the fade takes.
@export var duration := 0.8


func play(run: CutsceneRun) -> void:
	var fade := run.cutscene.get_tree().get_first_node_in_group(ScreenFade.GROUP) as ScreenFade
	if fade:
		await run.until(fade.fade_to(1.0 if to_black else 0.0, duration).finished)
