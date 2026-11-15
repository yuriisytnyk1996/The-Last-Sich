class_name StateMachine
extends Node
## Generic finite state machine. Reusable for the player, enemies and bosses.
##
## Every child node that extends State is a state. Only the current state
## runs each frame, and each state decides on its own when to leave.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var state: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		var child_state := child as State
		if child_state:
			_states[child_state.name] = child_state
			child_state.finished.connect(transition_to)

	# Wait until the owner (e.g. Player) is ready, so states can use its @onready vars.
	await owner.ready
	state = initial_state if initial_state else _states.values()[0]
	state.enter(&"")


func _unhandled_input(event: InputEvent) -> void:
	if state:
		state.handle_input(event)


func _process(delta: float) -> void:
	if state:
		state.update(delta)


func _physics_process(delta: float) -> void:
	if state:
		state.physics_update(delta)


func transition_to(target: StringName) -> void:
	if not _states.has(target):
		push_error("%s: no state named '%s'" % [owner.name, target])
		return

	var previous: StringName = state.name if state else &""
	if state:
		state.exit()
	state = _states[target]
	state.enter(previous)
	state_changed.emit(previous, target)
