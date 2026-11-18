class_name CallStep
extends CutsceneStep
## Calls `method` on the node at `node` with `arguments`: open a gate
## (`set_open`, `[true]`), show a hidden node (`show`), wake an enemy.
## Skipped before it ran: called then, unless `on_skip` is off (a sound,
## an effect that only matters to watch).

## From the cutscene.
@export var node: NodePath
@export var method := &""
@export var arguments: Array = []
@export var on_skip := true


func play(run: CutsceneRun) -> void:
	_call(run)


func skip(run: CutsceneRun) -> void:
	if on_skip:
		_call(run)


func _call(run: CutsceneRun) -> void:
	var target := run.node(node)
	if target == null:
		return
	if not target.has_method(method):
		push_warning("CallStep: %s has no method %s" % [target.name, method])
		return
	target.callv(method, arguments)
