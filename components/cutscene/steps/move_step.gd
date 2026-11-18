class_name MoveStep
extends CutsceneStep
## Moves a node (an NPC) to `to` (a `Marker2D`) in a straight line over
## `duration` seconds, turning its `Visual` child toward the way it goes.
## Skipped: the node is put on the spot.

## The node to move, from the cutscene.
@export var node: NodePath
@export var to: NodePath
@export var duration := 2.0


func play(run: CutsceneRun) -> void:
	var target := run.node(node) as Node2D
	if target == null:
		return
	var end := run.point(to)
	var visual := target.get_node_or_null(^"Visual") as Node2D
	if visual and end.x != target.global_position.x:
		visual.scale.x = signf(end.x - target.global_position.x)
	var tween := target.create_tween()
	tween.tween_property(target, ^"global_position", end, duration)
	run.memory[self] = tween
	await run.until(tween.finished)


func skip(run: CutsceneRun) -> void:
	var tween := run.memory.get(self) as Tween
	if tween:
		tween.kill()
	var target := run.node(node) as Node2D
	if target:
		target.global_position = run.point(to)
