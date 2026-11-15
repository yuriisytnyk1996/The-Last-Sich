class_name RoomExit
extends Area2D
## A doorway to another room, usually a gap at the screen edge.
##
## When the player touches it, it asks the world to load `target_room` and
## place the player at the exit named `target_exit` there. The node's own
## name is its id, so the other room's exit points back at it by name.
## Its `Landing` marker is where players arriving through it stand: keep it
## outside the area, or they would bounce straight back.

@export_file("*.tscn") var target_room := ""
@export var target_exit: StringName

@onready var landing: Marker2D = $Landing


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and target_room != "":
		Events.room_change_requested.emit(target_room, target_exit)
