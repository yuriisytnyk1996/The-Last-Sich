class_name RoomExit
extends InteractionArea
## A way into another room: a gap at the screen edge, a hole in the floor,
## an opening in the ceiling, or a door the player enters by pressing up
## (`press_up` on, see `door.tscn`).
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
## For an opening in the floor that players come up through from the room
## below: how high (px) they rise after arriving while moving up, so they
## clear the hole and can steer onto the ground beside it. 0 keeps their speed.
@export var arrival_rise := 0.0
## Off when the landing isn't safe ground (mid-air, over a hole). A death in
## this room then respawns the player at the room's SpawnPoint instead.
@export var respawn_here := true

@onready var landing: Marker2D = $Landing


## Places a player arriving through this exit.
func receive(player: Player) -> void:
	player.global_position = landing.global_position
	if arrival_facing != 0:
		player.set_facing(arrival_facing)
	if arrival_rise > 0.0 and player.velocity.y < 0.0:
		player.velocity.y = -sqrt(2.0 * player.jump_gravity * arrival_rise)
		# Fall, not Jump: releasing jump must not cut the boost short.
		player.state_machine.transition_to(PlayerState.FALL)


func _activate(_player: Node2D) -> void:
	if target_room != "":
		Events.room_change_requested.emit(target_room, target_exit)
