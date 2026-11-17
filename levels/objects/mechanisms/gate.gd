class_name Gate
extends Node2D
## A gate that blocks the way until something opens it: a `Lever`, or any
## script calling `toggle()` or `set_open()`. Opening shuts off its
## collision and folds its `Visual` up toward the top; closing brings
## both back.
##
## The origin is the bottom centre. Children: `Body` (a `StaticBody2D` on
## the `world` layer whose `Shape` is the closed gate) and `Visual`
## (placed at the top of the gate, drawn downward). Put it in the room's
## `Logic`. Saved (`persistent` group), so an opened shortcut stays open.
##
## A `locked` gate ignores `toggle()` and `set_open()` until `unlock()`:
## a lever in unlock mode, or a script, frees it, then something else
## opens it.

## The state when the room is first entered.
@export var open := false
## Ignores `toggle()` and `set_open()` until `unlock()`.
@export var locked := false
## Seconds the gate takes to open or close.
@export var move_time := 0.5
## Camera trauma when it moves (0 to 1).
@export var move_shake := 0.2
## How much of the gate still shows when open (0 to 1).
@export_range(0.0, 1.0) var open_scale := 0.1

var _tween: Tween

@onready var shape: CollisionShape2D = $Body/Shape
@onready var visual: Node2D = $Visual


func _ready() -> void:
	add_to_group(SaveManager.PERSISTENT_GROUP)
	_apply(true)


func toggle() -> void:
	set_open(not open)


## Lets `toggle()` and `set_open()` work again.
func unlock() -> void:
	locked = false


func set_open(value: bool, instant := false) -> void:
	if locked or (value == open and not instant):
		return
	open = value
	_apply(instant)
	if not instant:
		Events.camera_shake_requested.emit(move_shake)


func get_save_data() -> Dictionary:
	return {"open": open, "locked": locked}


func apply_save_data(data: Dictionary) -> void:
	var saved_lock := bool(data.get("locked", locked))
	locked = false
	set_open(bool(data.get("open", open)), true)
	locked = saved_lock


func _apply(instant: bool) -> void:
	# Deferred: collision can't change during a physics callback.
	shape.set_deferred(&"disabled", open)
	var target := open_scale if open else 1.0
	if _tween:
		_tween.kill()
	if instant:
		visual.scale.y = target
	else:
		_tween = create_tween()
		_tween.tween_property(visual, ^"scale:y", target, move_time)
