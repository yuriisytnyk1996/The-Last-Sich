class_name Cutscene
extends Node2D
## A scripted scene in a room: takes control from the player, plays its
## `steps` one after another (walk the player, move the camera, a
## conversation, a gate opening) and hands control back.
##
## While it plays the HUD hides and letterbox bars slide in
## (`Events.cutscene_started`), the player is in the `Scripted` state and
## can't be hurt, and the room's enemies are frozen (`freeze_enemies` off
## lets them move, for an ambush). The pause, map and inventory buttons
## are taken: a first press of pause offers the skip, a second one skips.
## A skip fades to black, finishes every remaining step at once
## (`CutsceneStep.skip()`) and fades back in.
##
## It starts from a `CutsceneTrigger` child, when the room is entered
## (`play_on_enter`), when a signal of `source` fires (`signal_name`), or
## from a script calling `play()` (a `BossArena` intro). Paths in the steps
## are read from this node. With a `flag` it plays once: the flag is set
## in `PlayerStory` when it ends, skipped or not. Saves nothing itself.

## The cutscene ended and the player has control again.
signal finished

## The cutscene playing now is in this group. Only one plays at a time.
const PLAYING_GROUP := &"cutscenes"
## Buttons taken while it plays. Pause asks to skip.
const TAKEN_ACTIONS: Array[StringName] = [&"pause", &"map", &"inventory"]

@export var steps: Array[CutsceneStep] = []
## Set when it ends. While set, it doesn't play again. Empty: every time.
@export var flag := &""
## Plays only while this holds. Empty: always.
@export var condition: StoryCondition

@export_group("Start")
## Plays when the room is entered, `enter_delay` seconds after the fade in.
@export var play_on_enter := false
@export var enter_delay := 0.4
## Plays when this node's `signal_name` fires.
@export var source: Node
@export var signal_name := &""

@export_group("Presentation")
@export var letterbox := true
@export var skippable := true
@export var freeze_enemies := true
## Seconds the camera takes to come back if the last step left it away.
@export var camera_return_time := 0.6
## Seconds of each half of the black fade that covers a skip.
@export var skip_fade_time := 0.3
## Seconds the skip stays offered after the first press of pause.
@export var skip_offer_time := 2.0

var _run: CutsceneRun
var _frozen: Array[Enemy] = []
var _skip_offered_until := 0


func _ready() -> void:
	if source and signal_name != &"":
		var arguments := CutsceneRun.argument_count(Signal(source, signal_name))
		source.connect(signal_name, play.unbind(arguments) if arguments > 0 else play)
	if play_on_enter:
		_play_on_enter.call_deferred()


func is_playing() -> bool:
	return _run != null


## Nothing else plays, the player is alive, the flag isn't set yet and
## the condition holds.
func can_play() -> bool:
	if is_playing() or get_tree().has_group(PLAYING_GROUP):
		return false
	var player := _player()
	if player == null or player.health.is_dead():
		return false
	if flag != &"" and player.story.has(flag):
		return false
	return StoryCondition.holds(condition, player)


## Plays the cutscene and returns once the player has control again.
## Does nothing when it can't play now.
func play() -> void:
	if not can_play():
		return
	var run := CutsceneRun.new(self, _player())
	_run = run
	_begin(run.player)
	for step in steps:
		if run.skipped:
			break
		if step.wait:
			await run.play_step(step)
		else:
			run.play_step(step)
	await run.settle()
	if run.skipped:
		await _finish_skipped(run)
	else:
		var tween := run.player.camera_director.glide_home(camera_return_time)
		if tween:
			await tween.finished
	_end(run.player)


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing():
		return
	for action in TAKEN_ACTIONS:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			if action == &"pause":
				_on_skip_pressed(event)
			return


func _on_skip_pressed(event: InputEvent) -> void:
	if not skippable or _run.skipped:
		return
	var now := Time.get_ticks_msec()
	if now <= _skip_offered_until:
		_run.skip()
		return
	_skip_offered_until = now + int(skip_offer_time * 1000.0)
	var binding := Tip.binding(&"pause", Tip.device_of(event) == 1)
	Events.cutscene_skip_offered.emit("[%s]" % binding, skip_offer_time)


func _begin(player: Player) -> void:
	add_to_group(PLAYING_GROUP)
	Events.cutscene_started.emit(letterbox)
	player.scripted.take()
	if freeze_enemies:
		_set_enemies_frozen(true)


## Under a black fade: every step that didn't finish skips to its end.
func _finish_skipped(run: CutsceneRun) -> void:
	var fade := get_tree().get_first_node_in_group(ScreenFade.GROUP) as ScreenFade
	if fade:
		await fade.fade_out(skip_fade_time)
	Events.cutscene_skipped.emit()
	for step in steps:
		if not run.is_finished(step):
			step.skip(run)
	run.player.camera_director.release()
	if fade:
		await fade.fade_in(skip_fade_time)


func _end(player: Player) -> void:
	player.camera_director.release()
	if freeze_enemies:
		_set_enemies_frozen(false)
	player.scripted.release()
	if flag != &"":
		player.story.set_flag(flag)
	_run = null
	_skip_offered_until = 0
	remove_from_group(PLAYING_GROUP)
	Events.cutscene_ended.emit()
	finished.emit()


## Stops the room's enemies where they are, or lets them go again. Only
## the ones running now: a hidden one stays off.
func _set_enemies_frozen(frozen: bool) -> void:
	var room := _room()
	if frozen and room:
		_frozen = room.get_enemies().filter(
			func(enemy: Enemy) -> bool: return enemy.process_mode == PROCESS_MODE_INHERIT
		)
	for enemy in _frozen:
		if is_instance_valid(enemy):
			enemy.process_mode = PROCESS_MODE_DISABLED if frozen else PROCESS_MODE_INHERIT
	if not frozen:
		_frozen.clear()


## The room loads while the world is paused behind its fade.
func _play_on_enter() -> void:
	while get_tree().paused:
		await get_tree().process_frame
	await get_tree().create_timer(enter_delay, false).timeout
	play()


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player
