class_name MapSecrets
extends RefCounted
## The secrets of one room as `MapRoom.scan()` sees them: breakables with
## a `map_hides` area. While one is whole, what is in its area stays off
## the map (cells, exits and marks). Found through the breakables'
## hurtboxes, which are among the room's areas.

var _secrets: Array[Breakable] = []


func _init(areas: Array[Node]) -> void:
	for node in areas:
		var breakable := node.get_parent() as Breakable
		if breakable and breakable.map_hides.has_area() and not breakable in _secrets:
			_secrets.append(breakable)


## True while a secret not found yet hides `point` (global px).
func hides(point: Vector2) -> bool:
	for secret in _secrets:
		if secret.hides_on_map(point):
			return true
	return false
