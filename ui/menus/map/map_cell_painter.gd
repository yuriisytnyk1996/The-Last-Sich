class_name MapCellPainter
extends RefCounted
## Draws one world map cell for `MapView`: the fill, a wall on every side
## that is a room edge, and a gap in the middle of the wall for a door.
## Cells of the same room join with no line between them.


static func draw_cell(
	canvas: CanvasItem,
	rect: Rect2,
	cell: Vector2i,
	map_room: MapRoom,
	owners: Dictionary[Vector2i, MapRoom],
	fill: Color,
	wall: Color,
) -> void:
	canvas.draw_rect(rect, fill)
	var thickness := 2.0 if rect.size.x >= 32.0 else 1.0
	for side in MapRoom.Side.values():
		if owners.get(cell + MapRoom.SIDE_STEPS[side]) == map_room:
			continue
		var strip := _strip(rect, side, thickness)
		canvas.draw_rect(strip, wall)
		if map_room.has_door(cell, side):
			canvas.draw_rect(_gap(strip, side), fill)


## The wall along `side` of `rect`, `thickness` px thick.
static func _strip(rect: Rect2, side: int, thickness: float) -> Rect2:
	match side:
		MapRoom.Side.NORTH:
			return Rect2(rect.position, Vector2(rect.size.x, thickness))
		MapRoom.Side.SOUTH:
			return Rect2(rect.position.x, rect.end.y - thickness, rect.size.x, thickness)
		MapRoom.Side.WEST:
			return Rect2(rect.position, Vector2(thickness, rect.size.y))
		_:
			return Rect2(rect.end.x - thickness, rect.position.y, thickness, rect.size.y)


## The middle third of a wall strip.
static func _gap(strip: Rect2, side: int) -> Rect2:
	if side == MapRoom.Side.NORTH or side == MapRoom.Side.SOUTH:
		var third := floorf(strip.size.x / 3.0)
		return Rect2(
			strip.position.x + third, strip.position.y, strip.size.x - third * 2.0, strip.size.y
		)
	var third_y := floorf(strip.size.y / 3.0)
	return Rect2(
		strip.position.x, strip.position.y + third_y, strip.size.x, strip.size.y - third_y * 2.0
	)
