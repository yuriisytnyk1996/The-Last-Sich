class_name DeathMarkList
extends RefCounted
## The death marks waiting to be recovered: where each one is and which
## ones are linked. Plain data, owned and saved by `DeathPenalty`.
##
## A mark left close to an older one in the same room links to it: it gets
## no marker of its own, and recovering the older one recovers both. This
## keeps several deaths at one hard spot from piling up markers.

## Each mark: {id, room, x, y, linked (ids of marks linked to it), is_linked}
var marks: Array[Dictionary] = []
var _next_id := 1


func count() -> int:
	return marks.size()


## Adds a mark at `spot` in `room`. It links to the first unlinked mark in
## that room within `link_distance`.
func add(room: String, spot: Vector2, link_distance: float) -> void:
	var mark := {"id": _next_id, "room": room, "x": spot.x, "y": spot.y}
	mark["linked"] = []
	mark["is_linked"] = false
	_next_id += 1
	for other in marks:
		if other["is_linked"] or other["room"] != room:
			continue
		if spot_of(other).distance_to(spot) <= link_distance:
			mark["is_linked"] = true
			other["linked"].append(mark["id"])
			break
	marks.append(mark)


## Removes the mark `id` and every mark linked to it.
func recover(id: int) -> void:
	var mark := _find(id)
	if mark.is_empty():
		return
	for linked_id: int in mark["linked"]:
		marks.erase(_find(linked_id))
	marks.erase(mark)


func clear() -> void:
	marks.clear()


## The marks in `room` that have a marker of their own.
func shown_in(room: String) -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	for mark in marks:
		if mark["room"] == room and not mark["is_linked"]:
			shown.append(mark)
	return shown


static func spot_of(mark: Dictionary) -> Vector2:
	return Vector2(mark["x"], mark["y"])


func to_data() -> Dictionary:
	return {"marks": marks.duplicate(true), "next_id": _next_id}


## JSON gives numbers back as floats: convert them while reading.
func from_data(data: Dictionary) -> void:
	marks.clear()
	for saved: Variant in data.get("marks", []):
		if saved is Dictionary:
			marks.append(_read_mark(saved))
	_next_id = int(data.get("next_id", 1))


func _read_mark(saved: Dictionary) -> Dictionary:
	var linked: Array[int] = []
	for id: Variant in saved.get("linked", []):
		linked.append(int(id))
	return {
		"id": int(saved.get("id", 0)),
		"room": str(saved.get("room", "")),
		"x": float(saved.get("x", 0.0)),
		"y": float(saved.get("y", 0.0)),
		"linked": linked,
		"is_linked": bool(saved.get("is_linked", false)),
	}


func _find(id: int) -> Dictionary:
	for mark in marks:
		if mark["id"] == id:
			return mark
	return {}
