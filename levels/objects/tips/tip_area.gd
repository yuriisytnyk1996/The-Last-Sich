class_name TipArea
extends Area2D
## Shows a "how to play" card the first time the player walks in (see
## `TipLog`): a tip placed in a room, before a spot that needs it. Give it
## a `CollisionShape2D` child. It sits on no layer and masks only `player`.
##
## Nothing to save: `TipLog` remembers which tips were seen.

const PLAYER_LAYER := 2

@export var tip: Tip


func _init() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitorable = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Events.tip_requested.emit(tip)
