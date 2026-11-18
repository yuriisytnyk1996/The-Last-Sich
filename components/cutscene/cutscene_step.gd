class_name CutsceneStep
extends Resource
## One step of a `Cutscene`: walk the player, move the camera, play a
## conversation, open a gate. The cutscene plays its steps in order;
## `play()` returns when the step is over. With `wait` off the cutscene
## goes on to the next step at once and this one runs alongside it (the
## camera glides while the player walks).
##
## Skipping a cutscene cuts the running steps short and calls `skip()` on
## every step that didn't finish. `skip()` must leave the world as the step
## would have: the player at the end of the walk, the gate open, the flag set.

## Off: the next step starts at once, this one runs alongside it.
@export var wait := true


## Does the step. Waits go through `run.wait()` and `run.until()`, which
## return early on a skip.
func play(_run: CutsceneRun) -> void:
	pass


## Leaves the world as `play()` would have. Called on a skip for every
## step that didn't finish, cut short or never started.
func skip(_run: CutsceneRun) -> void:
	pass
