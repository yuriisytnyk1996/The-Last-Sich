class_name MapCatalog
extends Resource
## Every room of the game and the map cells it covers, so the map can
## count the cells left to explore without loading any room.
##
## Generated from the room scenes by `pnpm map:catalog`
## (`tools/build_map_catalog.gd`) into `levels/map/map_catalog.tres`.
## Don't edit it by hand. `WorldMap` warns when a loaded room doesn't
## match it.

## Room scene path -> its rectangle of map cells.
@export var rooms: Dictionary[String, Rect2i] = {}

var _cells: Dictionary[Vector2i, bool] = {}


## Every cell any room covers, once each.
func cells() -> Dictionary[Vector2i, bool]:
	if _cells.is_empty():
		for rect: Rect2i in rooms.values():
			for x in rect.size.x:
				for y in rect.size.y:
					_cells[rect.position + Vector2i(x, y)] = true
	return _cells


## The map rectangle of a room with `bounds` (px) at `map_cell`, as
## `MapRoom.scan()` makes it.
static func rect_for(map_cell: Vector2i, bounds: Rect2i, cell_size: Vector2i) -> Rect2i:
	var size := Vector2i(
		ceili(float(bounds.size.x) / cell_size.x), ceili(float(bounds.size.y) / cell_size.y)
	)
	return Rect2i(map_cell, size.max(Vector2i.ONE))
