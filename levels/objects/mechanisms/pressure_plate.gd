class_name PressurePlate
extends Area2D
## A plate on the floor pressed by standing on it: the player or an enemy.
## Pressing calls `set_open(true)` on each node in `targets` (a `Gate`, or
## any node with that method).
##
## HOLD keeps the targets open only while something stands on the plate.
## Stepping off closes them after `release_delay`, which makes timed
## gates the player has to run through. A HOLD plate owns its targets:
## when the room loads with nothing on it, it closes them at once, so a
## gate saved open by a room change doesn't stay open.
##
## LATCH stays down after the first press and keeps the targets open.
## Saved (`persistent` group), for one-time shortcuts.
##
## The origin is the bottom centre: place it on the floor in the room's
## `Logic`. Children: `Shape` (what presses it) and `Top` (sinks when
## pressed).

enum Mode { HOLD, LATCH }

## Nodes to open, each with `set_open(open: bool)`.
@export var targets: Array[Node] = []
@export var mode := Mode.HOLD
## HOLD only: seconds after stepping off before the targets close.
@export var release_delay := 0.0
## How far `Top` sinks when pressed (px).
@export var press_depth := 2.0

var pressed := false

var _bodies := 0
var _release_timer: SceneTreeTimer

@onready var top: Node2D = $Top
@onready var _top_y := top.position.y


func _ready() -> void:
	add_to_group(SaveManager.PERSISTENT_GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Deferred: runs after the room has restored its saved state.
	_settle.call_deferred()


func get_save_data() -> Dictionary:
	return {"pressed": pressed and mode == Mode.LATCH}


func apply_save_data(data: Dictionary) -> void:
	if mode == Mode.LATCH and bool(data.get("pressed", false)):
		pressed = true
		_show_top()


func _settle() -> void:
	if mode == Mode.HOLD and _bodies == 0:
		_drive(false, true)


func _on_body_entered(_body: Node2D) -> void:
	_bodies += 1
	_release_timer = null
	if pressed:
		return
	pressed = true
	_show_top()
	_drive(true)


func _on_body_exited(_body: Node2D) -> void:
	_bodies = maxi(_bodies - 1, 0)
	# The room is unloading: nothing to close.
	if not is_inside_tree() or mode == Mode.LATCH or _bodies > 0:
		return
	if release_delay <= 0.0:
		_release()
		return
	var timer := get_tree().create_timer(release_delay, false)
	_release_timer = timer
	await timer.timeout
	# A new press or a later step-off replaced this timer.
	if _release_timer == timer:
		_release()


func _release() -> void:
	_release_timer = null
	pressed = false
	_show_top()
	_drive(false)


func _drive(open: bool, instant := false) -> void:
	for target in targets:
		if target and target.has_method(&"set_open"):
			target.call(&"set_open", open, instant)
		else:
			push_warning("PressurePlate %s: target %s has no set_open()" % [name, target])


func _show_top() -> void:
	top.position.y = _top_y + (press_depth if pressed else 0.0)
