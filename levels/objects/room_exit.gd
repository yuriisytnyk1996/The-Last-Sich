class_name RoomExit
extends InteractionArea
## A way into another room: a gap at the screen edge, or a door the player
## enters by pressing up (`press_up` on, see `door.tscn`).
##
## When set off, it asks the world to load `target_room` and place the
## player at the exit named `target_exit` there. The node's own name is its
## id, so the other room's exit points back at it by name.
## Its `Landing` marker is where players arriving through it stand. For
## touch exits keep it outside the area, or they would bounce straight back.

@export_file("*.tscn") var target_room := ""
@export var target_exit: StringName
## Which way the player faces after arriving through this exit.
@export_enum("Keep:0", "Left:-1", "Right:1") var arrival_facing := 0

@onready var landing: Marker2D = $Landing


## Places a player arriving through this exit.
func receive(player: Player) -> void:
	player.global_position = landing.global_position
	if arrival_facing != 0:
		player.set_facing(arrival_facing)


func _activate(_player: Node2D) -> void:
	if target_room != "":
		Events.room_change_requested.emit(target_room, target_exit)
