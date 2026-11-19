extends Node
## Plays sound cues by name (autoload "Audio"). Names come from the
## `SoundBank` at `BANK_PATH`; an empty name plays nothing, so an unset
## `@export` sound is simply silent.
##
## `play_at()` is for sounds in the world: heard from where they happen
## (panned and quieter far from the camera) and paused with the game.
## `play()` is for sounds on the screen (menus, pickups): no position, and
## they keep playing while the game is paused. Players are made once and
## reused; when all are busy the oldest is cut.
##
## Some sounds follow global events (`EVENT_CUES`), and every button in
## any menu sounds when focus moves (`ui_move`) or it is pressed
## (`ui_accept`).

const BANK_PATH := "res://assets/audio/sound_bank.tres"
const WORLD_VOICES := 24
const SCREEN_VOICES := 8
## Distance from the camera (px) where a world sound fades out.
const HEARING_DISTANCE := 700.0
## `Events` signal: cue.
const EVENT_CUES: Dictionary[StringName, StringName] = {
	&"item_obtained": &"item",
	&"currency_earned": &"coin",
	&"player_upgraded": &"upgrade",
	&"rested": &"rest",
	&"spirit_short": &"denied",
	&"player_flasks_empty": &"denied",
}

var bank: SoundBank
var _world: Array[Node] = []
var _screen: Array[Node] = []
var _last_start: Dictionary[StringName, int] = {}
var _warned: Dictionary[StringName, bool] = {}
var _focus: Control


func _ready() -> void:
	bank = load(BANK_PATH) if ResourceLoader.exists(BANK_PATH) else SoundBank.new()
	for i in WORLD_VOICES:
		var player := AudioStreamPlayer2D.new()
		player.max_distance = HEARING_DISTANCE
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		_world.append(player)
		add_child(player)
	for i in SCREEN_VOICES:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		_screen.append(player)
		add_child(player)
	_connect_events()
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	get_tree().node_added.connect(_on_node_added)


## A sound on the screen: menus, pickups, messages.
func play(cue: StringName) -> void:
	_start(cue, _screen, Vector2.ZERO)


## A sound in the world at `position` (global px).
func play_at(cue: StringName, position: Vector2) -> void:
	_start(cue, _world, position)


func _start(cue: StringName, players: Array[Node], position: Vector2) -> void:
	var sound := _find(cue)
	if sound == null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_start.get(cue, -100000) < sound.cooldown * 1000.0:
		return
	_last_start[cue] = now
	var player := _voice(players, cue, sound.max_voices)
	player.set(&"stream", sound.pick())
	player.set(&"volume_db", sound.volume_db)
	player.set(&"pitch_scale", sound.pick_pitch())
	player.set(&"bus", sound.bus)
	if player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).global_position = position
	player.set_meta(&"cue", cue)
	player.set_meta(&"started", now)
	player.call(&"play")


func _find(cue: StringName) -> SoundCue:
	if cue == &"":
		return null
	var sound := bank.get_cue(cue)
	if sound == null and not _warned.has(cue):
		_warned[cue] = true
		push_warning("Audio: no sound cue named %s" % cue)
	return sound


## A free player, or the oldest one playing this cue once it has
## `max_voices` going, or the oldest of all.
func _voice(players: Array[Node], cue: StringName, max_voices: int) -> Node:
	var free: Node
	var oldest: Node
	var oldest_same: Node
	var same := 0
	for player in players:
		if not player.call(&"is_playing"):
			free = player if free == null else free
			continue
		if oldest == null or _started(player) < _started(oldest):
			oldest = player
		if player.get_meta(&"cue") == cue:
			same += 1
			if oldest_same == null or _started(player) < _started(oldest_same):
				oldest_same = player
	if same >= max_voices:
		return oldest_same
	return free if free else oldest


func _started(player: Node) -> int:
	return player.get_meta(&"started", 0)


func _connect_events() -> void:
	for info in Events.get_signal_list():
		var cue: StringName = EVENT_CUES.get(StringName(info.name), &"")
		if cue == &"":
			continue
		var callable := play.bind(cue)
		var args: int = info.args.size()
		Events.connect(info.name, callable.unbind(args) if args > 0 else callable)


## Moving between buttons clicks; the first focus of a new menu doesn't.
func _on_focus_changed(control: Control) -> void:
	if is_instance_valid(_focus) and _focus.is_visible_in_tree():
		play(&"ui_move")
	_focus = control


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind(&"ui_accept"))
