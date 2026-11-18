class_name WaitStep
extends CutsceneStep
## A pause between steps: let a gate finish moving, a line sink in.

@export var seconds := 1.0


func play(run: CutsceneRun) -> void:
	await run.wait(seconds)
