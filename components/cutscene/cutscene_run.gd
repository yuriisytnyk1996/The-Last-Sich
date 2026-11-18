class_name CutsceneRun
extends RefCounted
## One playing of a `Cutscene`: what its steps work with (the player,
## nodes found from the cutscene) and the skip. Every wait made through
## it ends early on a skip, so a step never holds a skip up.

## Wakes the waits: a signal they wait for fired, or the cutscene was skipped.
signal woken

var cutscene: Cutscene
var player: Player
var skipped := false
## Per-step scratch data for this run (a tween to stop on a skip).
var memory := {}
var _finished: Dictionary[CutsceneStep, bool] = {}
var _running := 0


func _init(playing: Cutscene, playing_player: Player) -> void:
	cutscene = playing
	player = playing_player


## The node at `path`, from the cutscene node. Null when missing.
func node(path: NodePath) -> Node:
	var found := cutscene.get_node_or_null(path)
	if found == null:
		push_warning("Cutscene %s: no node at %s" % [cutscene.name, path])
	return found


## The global position of the node at `path` (a `Marker2D`), or the
## player's when missing.
func point(path: NodePath) -> Vector2:
	var marker := node(path) as Node2D
	return marker.global_position if marker else player.global_position


## Plays `step` and remembers whether it finished.
func play_step(step: CutsceneStep) -> void:
	_running += 1
	await step.play(self)
	_running -= 1
	if not skipped:
		_finished[step] = true
	woken.emit()


func is_finished(step: CutsceneStep) -> bool:
	return _finished.has(step)


## Waits until every step started so far is over (or a skip).
func settle() -> void:
	while _running > 0 and not skipped:
		await woken


## Waits `seconds` of game time (paused while the game is).
func wait(seconds: float) -> void:
	if skipped or seconds <= 0.0:
		return
	await until(cutscene.get_tree().create_timer(seconds, false).timeout)


## Waits until `done` fires or the cutscene is skipped.
func until(done: Signal) -> void:
	if skipped:
		return
	var state := {"fired": false}
	var on_done := func() -> void:
		state["fired"] = true
		woken.emit()
	var arguments := argument_count(done)
	var callback := on_done.unbind(arguments) if arguments > 0 else on_done
	done.connect(callback, CONNECT_ONE_SHOT)
	while not state["fired"] and not skipped:
		await woken
	if is_instance_valid(done.get_object()) and done.is_connected(callback):
		done.disconnect(callback)


func skip() -> void:
	skipped = true
	woken.emit()


## How many arguments `done` passes, so a callback can drop them.
static func argument_count(done: Signal) -> int:
	for info in done.get_object().get_signal_list():
		if info.name == done.get_name():
			return info.args.size()
	return 0
