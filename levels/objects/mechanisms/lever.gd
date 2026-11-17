class_name Lever
extends InteractionArea
## A lever pulled with interact. Every pull flips it and calls a method
## on each node in `targets`: `toggle()` (a `Gate` opens or closes) or,
## with `action` set to UNLOCK, `unlock()` (a locked gate can then be
## opened by something else). Any node with the method works. With
## `one_shot` it stays pulled and can't be used again, which suits
## shortcuts. With a `key` it only moves for a player carrying that item.
##
## Put it in the room's `Logic`. Saved (`persistent` group): the lever
## remembers being pulled. Its targets save their own state, so loading
## a room never toggles them again.

## TOGGLE calls `toggle()` on the targets, UNLOCK calls `unlock()`.
enum Action { TOGGLE, UNLOCK }

## Nodes to drive on each pull. Each needs the method `action` calls.
@export var targets: Array[Node] = []
@export var action := Action.TOGGLE
## The player must carry this item to pull the lever. Not used up.
@export var key: Item
@export var one_shot := true
## Handle angle when up and when pulled (radians).
@export var up_angle := -0.6
@export var pulled_angle := 0.6

var pulled := false

@onready var handle: Node2D = $Handle


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)
	_show_handle()


func _activate(body: Node2D) -> void:
	if key and not (body as Player).inventory.owns(key):
		return
	pulled = not pulled
	_show_handle()
	var method := &"toggle" if action == Action.TOGGLE else &"unlock"
	for target in targets:
		if target and target.has_method(method):
			target.call(method)
		else:
			push_warning("Lever %s: target %s has no %s()" % [name, target, method])
	if one_shot:
		block()


func get_save_data() -> Dictionary:
	return {"pulled": pulled}


func apply_save_data(data: Dictionary) -> void:
	pulled = bool(data.get("pulled", false))
	_show_handle()
	if pulled and one_shot and not is_blocked():
		block()


func _show_handle() -> void:
	handle.rotation = pulled_angle if pulled else up_angle
