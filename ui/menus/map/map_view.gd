class_name MapView
extends Control
## Draws the world map from a `WorldMap`: every revealed cell filled with
## its zone's colour, walls on room edges with gaps for doors, marks, the
## player (blinking) and a cursor in the middle. Move pans the view (it
## stays over revealed cells), jump switches between two zoom levels.

## The zone under the cursor changed ("" over an empty spot).
signal zone_changed(zone: String)

const ZONE_COLORS := {
	"Steppe": Color(0.42, 0.36, 0.2),
	"Caves": Color(0.26, 0.3, 0.38),
	"Works": Color(0.4, 0.27, 0.22),
}
const DEFAULT_ZONE_COLOR := Color(0.35, 0.35, 0.35)
const BACKGROUND := Color(0.05, 0.04, 0.07)
const FRAME_COLOR := Color(0.45, 0.4, 0.3)
const WALL_COLOR := Color(0.92, 0.88, 0.76)
const PLAYER_CELL_COLOR := Color(0.75, 0.62, 0.3)
const PLAYER_COLOR := Color(1, 1, 1)
const CURSOR_COLOR := Color(0.95, 0.8, 0.35)
const MARK_COLORS := {
	MapRoom.Mark.REST_POINT: Color(1, 0.55, 0.15),
	MapRoom.Mark.SHRINE: Color(0.4, 0.85, 0.95),
	MapRoom.Mark.DOOR: Color(0.62, 0.42, 0.25),
	MapRoom.Mark.DEATH_MARK: Color(0.9, 0.15, 0.15),
	MapRoom.Mark.SHOP: Color(0.95, 0.8, 0.35),
	MapRoom.Mark.CLEANSE: Color(0.85, 0.9, 1),
	MapRoom.Mark.UPGRADE: Color(0.75, 0.45, 0.95),
}
## One cell on screen (px), per zoom level. Same shape as a map cell.
const ZOOMS: Array[Vector2] = [Vector2(32, 18), Vector2(16, 9)]

## Panning speed, in cells per second.
@export var pan_speed := 6.0

## The map cell (not rounded) shown in the middle of the view.
var center := Vector2.ZERO

var _map: WorldMap
var _zoom := 0
## Every cell of every known room -> its room.
var _owners: Dictionary[Vector2i, MapRoom] = {}
var _death_cells: Array[Vector2i] = []
var _player := Vector2.ZERO
var _limits := Rect2()
var _blink := 0.0
var _zone := ""


func setup(map: WorldMap) -> void:
	_map = map
	for map_room: MapRoom in map.rooms.values():
		for x in map_room.rect.size.x:
			for y in map_room.rect.size.y:
				_owners[map_room.rect.position + Vector2i(x, y)] = map_room
	_death_cells = map.death_mark_cells()
	_player = map.player_position()
	center = _player
	_limits = Rect2(_player, Vector2.ZERO)
	for cell in map.revealed:
		_limits = _limits.merge(Rect2(Vector2(cell), Vector2.ONE))


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	clip_contents = true


func _process(delta: float) -> void:
	var move := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	move += Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	center += move.limit_length(1.0) * pan_speed * delta
	center = center.clamp(_limits.position, _limits.end)
	_blink = fmod(_blink + delta, 1.0)
	_update_zone()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump"):
		_zoom = (_zoom + 1) % ZOOMS.size()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var player_cell := Vector2i(_player.floor())
	for cell in _map.revealed:
		var map_room: MapRoom = _owners.get(cell)
		if map_room:
			var fill := PLAYER_CELL_COLOR if cell == player_cell else _zone_color(map_room.zone)
			MapCellPainter.draw_cell(
				self, _cell_rect(cell), cell, map_room, _owners, fill, WALL_COLOR
			)
	for cell in _map.revealed:
		var map_room: MapRoom = _owners.get(cell)
		if map_room:
			_draw_marks(cell, map_room.marks.get(cell, []))
	for cell in _death_cells:
		_draw_marks(cell, [MapRoom.Mark.DEATH_MARK])
	if _blink < 0.6:
		var dot := _to_screen(_player).floor() - Vector2.ONE
		draw_rect(Rect2(dot, Vector2(3, 3)), PLAYER_COLOR)
	_draw_cursor()
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)


func _draw_marks(cell: Vector2i, marks: Array) -> void:
	var rect := _cell_rect(cell)
	var side := 4.0 if _zoom == 0 else 2.0
	var start := (
		rect.get_center() - Vector2(side * 1.5 * (marks.size() - 1) * 0.5 + side * 0.5, side * 0.5)
	)
	for i in marks.size():
		var spot := (start + Vector2(i * side * 1.5, 0)).floor()
		draw_rect(Rect2(spot, Vector2(side, side)), MARK_COLORS[marks[i]])


func _draw_cursor() -> void:
	var mid := (size * 0.5).floor()
	for step: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_rect(Rect2(mid + step * 3.0, Vector2.ONE), CURSOR_COLOR)
		draw_rect(Rect2(mid + step * 4.0, Vector2.ONE), CURSOR_COLOR)


func _update_zone() -> void:
	var cell := Vector2i(center.floor())
	var zone := ""
	if _map.revealed.has(cell) and _owners.has(cell):
		zone = _owners[cell].zone
	if zone != _zone:
		_zone = zone
		zone_changed.emit(zone)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(_to_screen(Vector2(cell)), ZOOMS[_zoom])


func _to_screen(map_position: Vector2) -> Vector2:
	return ((map_position - center) * ZOOMS[_zoom] + size * 0.5).round()


func _zone_color(zone: String) -> Color:
	return ZONE_COLORS.get(zone, DEFAULT_ZONE_COLOR)
