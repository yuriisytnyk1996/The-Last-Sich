class_name MapView
extends Control
## Draws the world map from a `WorldMap`: every revealed cell filled with
## its zone's colour, walls on room edges with gaps for doors, marks, the
## player (blinking), the player's own marks and a cursor in the middle.
## Move pans the view (it stays over revealed cells), jump switches between
## two zoom levels. Attack on the cursor's cell removes the player's mark
## there, or opens a `MapMarkPicker` to place one.
##
## In travel mode (`setup(map, true)`) a `MapTravel` takes over: the cursor
## hops between rest points, zoom and marks are off, and attack on a rest
## point sends `travel_chosen`.

## The zone under the cursor changed ("" over an empty spot).
signal zone_changed(zone: String)
## The mark picker opened (true) or closed (false).
signal picking_changed(picking: bool)
## Travel mode: the player chose the rest point on `cell`.
signal travel_chosen(cell: Vector2i)

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
## Travel mode only, else null.
var travel: MapTravel

var _map: WorldMap
var _zoom := 0
## Every cell of every known room -> its room.
var _owners: Dictionary[Vector2i, MapRoom] = {}
var _death_cells: Array[Vector2i] = []
var _player := Vector2.ZERO
var _limits := Rect2()
var _blink := 0.0
var _zone := ""
var _picker := MapMarkPicker.new()


func setup(map: WorldMap, travel_mode := false) -> void:
	_map = map
	_owners = map.cell_owners()
	_death_cells = map.death_mark_cells()
	_player = map.player_position()
	center = _player
	_limits = Rect2(_player, Vector2.ZERO)
	for cell in map.revealed:
		_limits = _limits.merge(Rect2(Vector2(cell), Vector2.ONE))
	if travel_mode:
		travel = MapTravel.new()
		travel.setup(self, map, Vector2i(_player.floor()))
		add_child(travel)


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	_picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	_picker.chosen.connect(_on_mark_chosen)
	_picker.cancelled.connect(picking_changed.emit.bind(false))


func is_picking() -> bool:
	return _picker.visible


## One cell on screen (px) at the current zoom.
func cell_pixels() -> Vector2:
	return ZOOMS[_zoom]


func _process(delta: float) -> void:
	var move := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	move += Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if travel:
		travel.handle_move(move)
	elif not is_picking():
		center += move.limit_length(1.0) * pan_speed * delta
	center = center.clamp(_limits.position, _limits.end)
	_blink = fmod(_blink + delta, 1.0)
	_update_zone()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if travel:
		if event.is_action_pressed(&"attack") or event.is_action_pressed(&"ui_accept"):
			if travel.can_travel():
				travel_chosen.emit(travel.cell())
			accept_event()
	elif is_picking():
		if _picker.handle_input(event):
			accept_event()
	elif event.is_action_pressed(&"jump"):
		_zoom = (_zoom + 1) % ZOOMS.size()
		accept_event()
	elif event.is_action_pressed(&"attack"):
		_on_mark_pressed(Vector2i(center.floor()))
		accept_event()


## Removes the player's mark on `cell`, or opens the picker to place one.
func _on_mark_pressed(cell: Vector2i) -> void:
	if _map.player_marks.has(cell):
		_map.player_marks.remove(cell)
	elif _map.can_place_mark(cell):
		_picker.open()
		picking_changed.emit(true)


func _on_mark_chosen(kind: PlayerMarks.Kind) -> void:
	_map.player_marks.place(Vector2i(center.floor()), kind)
	picking_changed.emit(false)


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
			MapCellPainter.draw_marks(self, _cell_rect(cell), map_room.marks.get(cell, []))
	for cell in _map.player_marks.marks:
		if _owners.has(cell) and _map.revealed.has(cell):
			MapMarkPainter.draw_mark(
				self, _map.player_marks.marks[cell], _cell_rect(cell).get_center()
			)
	for cell in _death_cells:
		MapCellPainter.draw_marks(self, _cell_rect(cell), [MapRoom.Mark.DEATH_MARK])
	if _blink < 0.6:
		var dot := _to_screen(_player).floor() - Vector2.ONE
		draw_rect(Rect2(dot, Vector2(3, 3)), PLAYER_COLOR)
	_draw_cursor()
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)


func _draw_cursor() -> void:
	var mid := (size * 0.5).floor()
	if travel:
		travel.draw_cursor(self, mid)
		return
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
