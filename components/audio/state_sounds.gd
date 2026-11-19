class_name StateSounds
extends Node
## Plays sound cues when a `StateMachine` changes state: a jump, a
## landing, a death. Put it in an actor's scene and fill `sounds`.
##
## Keys are a state name (`"Jump"`: played whenever that state starts) or
## a change (`"Fall>Idle"`: played only coming from that state), which
## wins over the plain name. Footsteps repeat every `step_interval` while
## `step_state` runs. Attack swings belong on the hitbox (`Hitbox.sound`),
## which plays when the blow actually comes out.

@export var state_machine: StateMachine
## Where the sounds come from. The parent when empty.
@export var source: Node2D
@export var sounds: Dictionary[String, StringName] = {}
@export var step_state := &""
@export var step_sound := &""
@export_range(0.05, 2.0, 0.01, "suffix:s") var step_interval := 0.3

var _step_left := 0.0


func _ready() -> void:
	if source == null:
		source = get_parent() as Node2D
	state_machine.state_changed.connect(_on_state_changed)
	set_physics_process(step_state != &"" and step_sound != &"")


func _physics_process(delta: float) -> void:
	var state := state_machine.state
	if state == null or state.name != step_state:
		_step_left = step_interval * 0.5
		return
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = step_interval
		Audio.play_at(step_sound, source.global_position)


func _on_state_changed(from: StringName, to: StringName) -> void:
	var cue: StringName = sounds.get("%s>%s" % [from, to], sounds.get(String(to), &""))
	if cue != &"":
		Audio.play_at(cue, source.global_position)
