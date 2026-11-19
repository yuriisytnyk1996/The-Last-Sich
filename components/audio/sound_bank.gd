class_name SoundBank
extends Resource
## Every sound cue in the game by name (`assets/audio/sound_bank.tres`).
## Code and scenes only use cue names (`&"parry"`); this table says which
## files play, so sounds can be swapped without touching code.

@export var cues: Dictionary[StringName, SoundCue] = {}


func get_cue(cue: StringName) -> SoundCue:
	return cues.get(cue)
