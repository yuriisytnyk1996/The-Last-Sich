extends Node
## Music (autoload "Music"): one track at a time, crossfaded over `fade`
## seconds, on the Music bus. Keeps playing while the game is paused.
##
## The world sets each room's track (`Room.music`, through
## `set_room_music()`); rooms without one keep what is playing. A boss
## arena plays its own tracks over it (`play()`) and hands back with
## `play_room_music()`. Tracks loop: an Ogg imported with loop on loops by
## itself, anything else restarts when it ends.

const FADE := 1.5

## The current room's track (the last one set).
var room_music: AudioStream

var _players: Array[AudioStreamPlayer] = []
var _current := 0
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.finished.connect(player.play)
		_players.append(player)
		add_child(player)


## Crossfades to `stream`. The same track keeps playing; null fades out.
func play(stream: AudioStream, fade := FADE) -> void:
	if stream == current():
		return
	var old := _players[_current]
	_current = 1 - _current
	var new := _players[_current]
	if _tween:
		_tween.kill()
	new.stop()
	new.stream = stream
	if stream:
		new.volume_linear = 0.0
		new.play()
	_tween = create_tween().set_parallel().set_ignore_time_scale()
	_tween.tween_property(new, ^"volume_linear", 1.0, fade)
	_tween.tween_property(old, ^"volume_linear", 0.0, fade)
	_tween.chain().tween_callback(old.stop)


func stop(fade := FADE) -> void:
	play(null, fade)


## The track playing (or fading in), null for silence.
func current() -> AudioStream:
	var player := _players[_current]
	return player.stream if player.playing else null


## A room was entered. Null keeps the music that is playing.
func set_room_music(stream: AudioStream) -> void:
	if stream == null:
		return
	room_music = stream
	play(stream)


func play_room_music(fade := FADE) -> void:
	play(room_music, fade)
