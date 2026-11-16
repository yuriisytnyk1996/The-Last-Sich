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
## seen and the revealed cells.

@export var player: Player
@export var death_penalty: DeathPenalty
## World size of one map cell (px). Half a screen.
@export var cell_size := Vector2i(320, 180)
## How often the player's cell is checked (s).
@export var reveal_interval := 0.2

var save_id := &"world_map"

## Scene path -> `MapRoom`, for every room the player has been in.
var rooms: Dictionary[String, MapRoom] = {}
var revealed: Dictionary[Vector2i, bool] = {}

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
	rooms[_map_room.path] = _map_room
	_reveal_player_cell()


func _physics_process(delta: float) -> void:
	_wait += delta
	if _wait >= reveal_interval:
		_wait = 0.0
		_reveal_player_cell()


## The room the player is in.
func current_room() -> MapRoom:
	return _map_room


## The player's spot on the map, in cells, not rounded.
func player_position() -> Vector2:
	if not _map_room:
		return Vector2.ZERO
	return _map_room.map_position(_room.to_local(player.global_position), cell_size)


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
	var saved_rooms := {}
	for path in rooms:
		saved_rooms[path] = rooms[path].to_data()
	var cells := []
	for cell in revealed:
		cells.append([cell.x, cell.y])
	return {"rooms": saved_rooms, "revealed": cells}


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


func _reveal_player_cell() -> void:
	if _map_room and is_instance_valid(_room):
		var local := _room.to_local(player.global_position)
		revealed[_map_room.cell_at(local, cell_size)] = true


## Two rooms on the same cells would draw over each other on the map.
func _warn_overlaps(map_room: MapRoom) -> void:
	for path in rooms:
		if path != map_room.path and rooms[path].rect.intersects(map_room.rect):
			push_warning("Map: %s overlaps %s on the world map" % [map_room.path, path])
