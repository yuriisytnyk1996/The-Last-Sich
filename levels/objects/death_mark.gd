class_name DeathMark
extends InteractionArea
## A death mark waiting where the player last stood safely before dying.
## Pressing interact at it recovers it (see `DeathPenalty`). Spawned by
## the world, never placed in rooms by hand.
##
## A mark goes first: every press-interact area it overlaps (a door, a
## rest point) is blocked until the mark is gone, so one press never sets
## off both.

signal recovered(mark_id: int, player: Player)

var mark_id := 0
var _blocked: Array[InteractionArea] = []


func _ready() -> void:
	super()
	var bounds := get_bounds()
	for node in get_tree().get_nodes_in_group(InteractionArea.GROUP):
		var area := node as InteractionArea
		if area == self or area is DeathMark or not area.press_interact:
			continue
		if area.get_bounds().intersects(bounds):
			area.block()
			_blocked.append(area)


## Recovered, cleared, or its room unloaded: free what it blocked.
func _exit_tree() -> void:
	for area in _blocked:
		if is_instance_valid(area):
			area.unblock()
	_blocked.clear()


func _activate(body: Node2D) -> void:
	recovered.emit(mark_id, body as Player)
	queue_free()
