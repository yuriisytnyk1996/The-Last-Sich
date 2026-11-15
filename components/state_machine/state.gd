class_name State
extends Node
## Base class for one state of a StateMachine.
##
## Override the functions you need. To switch states, emit `finished`
## with the name of the next state node, then `return`.

signal finished(next_state: StringName)


## Called when the machine switches into this state.
func enter(_previous_state: StringName) -> void:
	pass


## Called right before the machine leaves this state.
func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
