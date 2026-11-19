class_name SoundCue
extends Resource
## One named sound in the `SoundBank`, played with `Audio.play()` or
## `Audio.play_at()`.
##
## It holds one or more takes of the same sound; each play picks one at
## random and shifts its pitch a little, so repeated hits don't sound
## identical. To replace a sound, point `streams` at new files (WAV or Ogg).

## Takes of the sound. One is picked at random each time.
@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db := 0.0
## Each play shifts the pitch by up to this fraction, up or down.
@export_range(0.0, 0.5, 0.01) var pitch_jitter := 0.05
@export var bus := &"Effects"
## Most copies of this cue playing at once. Another one cuts the oldest.
@export_range(1, 16) var max_voices := 4
## Seconds before this cue can start again. Several hits landing in the
## same frame play it once instead of stacking into a loud spike.
@export_range(0.0, 1.0, 0.01, "suffix:s") var cooldown := 0.03


func pick() -> AudioStream:
	return streams.pick_random() if not streams.is_empty() else null


func pick_pitch() -> float:
	return 1.0 + randf_range(-pitch_jitter, pitch_jitter)
