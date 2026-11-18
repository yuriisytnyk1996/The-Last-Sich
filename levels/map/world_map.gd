class_name WorldMap
extends Node
## The world map's data. The map is a grid of cells; each room covers a
## rectangle of them (`Room.map_cell`, `Room.bounds`). Cells are revealed
## one by one as the player walks through them, and only revealed cells
## are drawn (see `MapScreen`).
##
## A child of the `World`, which calls `enter_room()` on every room load.
## While playing, it checks the player's cell every `reveal_interval`.
## A global save system (see `SaveManager`): it saves the rooms it has
## seen, the revealed cells and the marks the player placed.
##
## `catalog` lists every room in the game, for `completion()`.

@export var player: Player
@export var death_penalty: DeathPenalty
## Every room and its cells. Generated, see `MapCatalog`.
@export var catalog: MapCatalog
## World size of one map cell (px). Half a screen.
@export var cell_size := Vector2i(320, 180)
## How often the player's cell is checked (s).
@export var reveal_interval := 0.2

var save_id := &"world_map"

## Scene path -> `MapRoom`, for every room the player has been in.
var rooms: Dictionary[String, MapRoom] = {}
var revealed: Dictionary[Vector2i, bool] = {}
var player_marks := PlayerMarks.new()

var _room: Room
var _map_room: MapRoom
var _wait := 0.0


func _ready() -> void:
	SaveManager.register(self)


## Scans `room` again (it may have changed since the save) and reveals
## the cell the player is in.
func enter_room(room: Room) -> void:
	_room = room
	_map_room = MapRoom.scan(room, cell_size)
	_warn_overlaps(_map_room)
	_check_catalog(_map_room)
	rooms[_map_room.path] = _map_room
	_reveal_player_cell()


func _physics_process(delta: float) -> void:
	_wait += delta
	if _wait >= reveal_interval:
		_wait = 0.0
		_reveal_player_cell()


## Scans the current room again, so the map follows what changed in it
## since it loaded (a secret wall broken shows what it hid).
## Called before the room unloads, before the map opens and on save.
func refresh() -> void:
	if _map_room and is_instance_valid(_room) and _room.is_inside_tree():
		_map_room = MapRoom.scan(_room, cell_size)
		rooms[_map_room.path] = _map_room


## The room the player is in.
func current_room() -> MapRoom:
	return _map_room


## Fraction (0 to 1) of all the game's map cells the player has revealed.
func completion() -> float:
	if not catalog or catalog.cells().is_empty():
		return 0.0
	var found := 0
	for cell in catalog.cells():
		if revealed.has(cell):
			found += 1
	return float(found) / catalog.cells().size()


## The player's spot on the map, in cells, not rounded.
func player_position() -> Vector2:
	if not _map_room:
		return Vector2.ZERO
	return _map_room.map_position(_room.to_local(player.global_position), cell_size)


## The known room that shows `cell` on the map, or null.
func room_at(cell: Vector2i) -> MapRoom:
	for map_room: MapRoom in rooms.values():
		if map_room.covers(cell):
			return map_room
	return null


## Every cell the map shows of every known room -> its room.
func cell_owners() -> Dictionary[Vector2i, MapRoom]:
	var owners: Dictionary[Vector2i, MapRoom] = {}
	for map_room: MapRoom in rooms.values():
		for x in map_room.rect.size.x:
			for y in map_room.rect.size.y:
				var cell := map_room.rect.position + Vector2i(x, y)
				if map_room.covers(cell):
					owners[cell] = map_room
	return owners


## A player mark may go on a revealed cell with no mark of its own (rest
## point, shop, door...) and no player mark yet.
func can_place_mark(cell: Vector2i) -> bool:
	var map_room := room_at(cell)
	return (
		revealed.has(cell)
		and map_room != null
		and map_room.marks.get(cell, []).is_empty()
		and not player_marks.has(cell)
	)


## Death marks waiting to be recovered, as map cells.
func death_mark_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not death_penalty:
		return cells
	for mark in death_penalty.get_shown_marks():
		var map_room: MapRoom = rooms.get(mark["room"])
		if map_room:
			cells.append(map_room.cell_at(mark["spot"], cell_size))
	return cells


func get_save_data() -> Dictionary:
	refresh()
	var saved_rooms := {}
	for path in rooms:
		saved_rooms[path] = rooms[path].to_data()
	var cells := []
	for cell in revealed:
		cells.append([cell.x, cell.y])
	return {
		"rooms": saved_rooms,
		"revealed": cells,
		"player_marks": player_marks.to_data(),
		# Read only by the slot list (`SlotSummary`); recomputed on load.
		"explored": completion(),
	}


func apply_save_data(data: Dictionary) -> void:
	rooms.clear()
	revealed.clear()
	var saved_rooms: Variant = data.get("rooms")
	if saved_rooms is Dictionary:
		for path: String in saved_rooms:
			rooms[path] = MapRoom.from_data(path, saved_rooms[path])
	var cells: Variant = data.get("revealed")
	if cells is Array:
		for cell: Array in cells:
			revealed[Vector2i(int(cell[0]), int(cell[1]))] = true
	player_marks.apply_data(data.get("player_marks"))


func _reveal_player_cell() -> void:
	if _map_room and is_instance_valid(_room):
		var local := _room.to_local(player.global_position)
		revealed[_map_room.cell_at(local, cell_size)] = true


## Two rooms on the same cells would draw over each other on the map.
func _warn_overlaps(map_room: MapRoom) -> void:
	for path in rooms:
		if path != map_room.path and rooms[path].rect.intersects(map_room.rect):
			push_warning("Map: %s overlaps %s on the world map" % [map_room.path, path])


## A room missing from the catalog, or moved or resized since it was
## built, makes `completion()` wrong.
func _check_catalog(map_room: MapRoom) -> void:
	if catalog and catalog.rooms.get(map_room.path) != map_room.rect:
		push_warning("Map: %s doesn't match the map catalog. Run pnpm map:catalog" % map_room.path)
