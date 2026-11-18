class_name WalkStep
extends CutsceneStep
## Walks the player to `to` (a `Marker2D`), then turns them to `facing`.
## Without `to` the player only turns. Skipped: the player is put on the
## spot at once.

## The spot to walk to, from the cutscene. Only its x counts.
@export var to: NodePath
@export_enum("Keep:0", "Left:-1", "Right:1") var facing := 0


func play(run: CutsceneRun) -> void:
	if to.is_empty():
		_turn(run)
		return
	var scripted := run.player.scripted
	scripted.walk_to(run.point(to).x, facing)
	await run.until(scripted.arrived)


func skip(run: CutsceneRun) -> void:
	if to.is_empty():
		_turn(run)
	else:
		run.player.scripted.place_at(run.point(to).x, facing)


func _turn(run: CutsceneRun) -> void:
	if facing != 0:
		run.player.set_facing(facing)
