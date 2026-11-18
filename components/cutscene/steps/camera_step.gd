class_name CameraStep
extends CutsceneStep
## Glides the camera to `to` (a `Marker2D`) and holds it there. Without
## `to` it glides back over the player and the camera follows them again.
## The room's camera limits still apply. Nothing to do on a skip: the
## camera goes back to the player when the cutscene ends.

## Where the view centres, from the cutscene. Empty: back to the player.
@export var to: NodePath
## Seconds the glide takes.
@export var duration := 1.0


func play(run: CutsceneRun) -> void:
	var director := run.player.camera_director
	if not to.is_empty():
		await run.until(director.pan_to(run.point(to), duration).finished)
		return
	var tween := director.glide_home(duration)
	if tween:
		await run.until(tween.finished)
	if not run.skipped:
		director.release()
