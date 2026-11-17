class_name MapRoom
extends RefCounted
## One room as the world map sees it: a rectangle of map cells, the doors
## on its edges and the marks inside it (rest points, shrines, shops,
## cleanse points, paid upgrade shrines, inner doors). Free upgrade
## shrines are secrets and get no mark.
##
## Rooms are only loaded one at a time, so `WorldMap` scans each room when
## it loads (`scan()`) and keeps the result in the save. Only rooms the
## player has been in are known, and the map only draws those.

enum Side { NORTH, SOUTH, WEST, EAST }
enum Mark { REST_POINT, SHRINE, DOOR, DEATH_MARK, SHOP, CLEANSE, UPGRADE }

## An exit this close to an edge of `bounds` (px) is a door in that edge.
const EDGE_MARGIN := 24

const SIDE_STEPS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var path := ""
var zone := ""
## Top left cell and size, in map cells.
var rect := Rect2i()
## The room position (px) at the top left corner of `rect`.
var origin := Vector2.ZERO
## Map cell -> Array of `Side`s with a door.
var doors: Dictionary[Vector2i, Array] = {}
## Map cell -> Array of `Mark`s.
var marks: Dictionary[Vector2i, Array] = {}


static func scan(room: Room, cell_size: Vector2i) -> MapRoom:
	var map_room := MapRoom.new()
	map_room.path = room.scene_file_path
	map_room.zone = room.map_zone
	var cells := Vector2i(
		ceili(float(room.bounds.size.x) / cell_size.x),
		ceili(float(room.bounds.size.y) / cell_size.y)
	)
	map_room.rect = Rect2i(room.map_cell, cells.max(Vector2i.ONE))
	map_room.origin = Vector2(room.bounds.position)
	for node in room.find_children("*", "Area2D", true, false):
		var local := room.to_local((node as Node2D).global_position)
		var cell := map_room.cell_at(local, cell_size)
		if node is RoomExit:
			map_room._add_exit(cell, _edge_of(local, room.bounds))
		elif node is RestPoint:
			map_room.add_mark(cell, Mark.REST_POINT)
		elif node is SkillShrine:
			map_room.add_mark(cell, Mark.SHRINE)
		elif node is CleansePoint:
			map_room.add_mark(cell, Mark.CLEANSE)
		elif node is StatUpgrade and (node as StatUpgrade).price > 0:
			map_room.add_mark(cell, Mark.UPGRADE)
		elif node is ShopItem and not Mark.SHOP in map_room.marks.get(cell, []):
			map_room.add_mark(cell, Mark.SHOP)
	return map_room


## The map cell under `local` (a position in the room), kept inside the room.
func cell_at(local: Vector2, cell_size: Vector2i) -> Vector2i:
	var offset := Vector2i(map_position(local, cell_size).floor()) - rect.position
	return rect.position + offset.clamp(Vector2i.ZERO, rect.size - Vector2i.ONE)


## `local` (a position in the room) on the map, in cells, not rounded.
func map_position(local: Vector2, cell_size: Vector2i) -> Vector2:
	return Vector2(rect.position) + (local - origin) / Vector2(cell_size)


func has_door(cell: Vector2i, side: Side) -> bool:
	return side in doors.get(cell, [])


func add_mark(cell: Vector2i, mark: Mark) -> void:
	if not marks.has(cell):
		marks[cell] = []
	marks[cell].append(mark)


func to_data() -> Dictionary:
	return {
		"zone": zone,
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"origin": [origin.x, origin.y],
		"doors": _cells_to_data(doors),
		"marks": _cells_to_data(marks),
	}


static func from_data(room_path: String, data: Dictionary) -> MapRoom:
	var map_room := MapRoom.new()
	map_room.path = room_path
	map_room.zone = str(data.get("zone", ""))
	var r: Array = data.get("rect", [0, 0, 1, 1])
	map_room.rect = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	var o: Array = data.get("origin", [0, 0])
	map_room.origin = Vector2(float(o[0]), float(o[1]))
	map_room.doors = _cells_from_data(data.get("doors", []))
	map_room.marks = _cells_from_data(data.get("marks", []))
	return map_room


## An exit on an edge is a gap in the wall, one inside the room is a door mark.
func _add_exit(cell: Vector2i, side: int) -> void:
	if side < 0:
		add_mark(cell, Mark.DOOR)
		return
	if not doors.has(cell):
		doors[cell] = []
	if not side in doors[cell]:
		doors[cell].append(side)


## The `Side` of `bounds` that `local` is on, or -1 when it is inside.
static func _edge_of(local: Vector2, bounds: Rect2i) -> int:
	var inner := Rect2(bounds).grow(-EDGE_MARGIN)
	if local.y < inner.position.y:
		return Side.NORTH
	if local.y > inner.end.y:
		return Side.SOUTH
	if local.x < inner.position.x:
		return Side.WEST
	if local.x > inner.end.x:
		return Side.EAST
	return -1


static func _cells_to_data(cells: Dictionary[Vector2i, Array]) -> Array:
	var data := []
	for cell in cells:
		data.append([cell.x, cell.y, cells[cell]])
	return data


static func _cells_from_data(data: Variant) -> Dictionary[Vector2i, Array]:
	var cells: Dictionary[Vector2i, Array] = {}
	if data is Array:
		for entry: Array in data:
			var values: Array = []
			for value: Variant in entry[2]:
				values.append(int(value))
			cells[Vector2i(int(entry[0]), int(entry[1]))] = values
	return cells
