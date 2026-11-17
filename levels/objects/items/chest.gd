class_name Chest
extends InteractionArea
## A chest opened once with interact. It gives its `item` (if any) and
## `currency` (as is, not scaled by the death penalty), then stays open.
##
## Put it in the room's `Logic`. Saved (`persistent` group), so an opened
## chest is open and empty for good.

@export var item: Item
@export var currency := 0
## Lid angle when open (radians).
@export var open_angle := -2.0

var opened := false

@onready var lid: Node2D = $Lid


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)


func _activate(body: Node2D) -> void:
	if opened:
		return
	_open()
	var player := body as Player
	if item:
		player.inventory.add(item)
	player.wallet.add(currency)


func get_save_data() -> Dictionary:
	return {"opened": opened}


func apply_save_data(data: Dictionary) -> void:
	if data.get("opened", false) and not opened:
		_open()


func _open() -> void:
	opened = true
	lid.rotation = open_angle
	# Blocked for good: no prompt and no more presses.
	block()
