extends Node
## Saves and loads the game (autoload "SaveManager").
##
## The game state lives in one snapshot dictionary with two parts:
## - `global`: one entry per registered system (the world's last rest
##   point, later the inventory...), keyed by the system's `save_id`.
## - `rooms`: one entry per room scene path. Inside, one entry per node in
##   the `persistent` group, keyed by its path inside the room.
##
## Both kinds of participant implement `get_save_data() -> Dictionary`
## and `apply_save_data(data: Dictionary)`. Rooms are stored into the
## snapshot when they unload and restored when they load. The snapshot is
## written to disk on `save_game()`. In debug builds F8 deletes the save
## and restarts the game.

## 2: rooms were split into Deco, Layout and Logic, so node paths changed.
const FORMAT_VERSION := 2
const PERSISTENT_GROUP := &"persistent"

var slot := 0
var _snapshot := _empty_snapshot()
var _systems: Array[Node] = []
var _busy := false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if OS.is_debug_build() and key and key.pressed and not key.echo:
		if key.physical_keycode == KEY_F8:
			delete_save()
			get_tree().reload_current_scene()
			get_viewport().set_input_as_handled()


## Adds a global system. It needs a `save_id` and the two save methods.
## It is dropped again when it leaves the tree.
func register(system: Node) -> void:
	if system in _systems:
		return
	_systems.append(system)
	system.tree_exiting.connect(_systems.erase.bind(system), CONNECT_ONE_SHOT)


func has_save() -> bool:
	return SaveFile.exists(slot)


## Reads the slot and hands every registered system its data. Returns
## false (and starts from a clean snapshot) when there is nothing to load.
func load_game() -> bool:
	_snapshot = _empty_snapshot()
	var data := SaveFile.read(slot)
	if data.is_empty() or int(data.get("version", 0)) != FORMAT_VERSION:
		return false
	_snapshot = data
	for system in _systems:
		var system_data: Variant = _snapshot.global.get(String(system.save_id))
		if system_data is Dictionary:
			system.apply_save_data(system_data)
	return true


## Stores `room` and every global system into the snapshot and writes it.
func save_game(room: Node) -> void:
	if not _enter():
		return
	_store_room(room)
	for system in _systems:
		_snapshot.global[String(system.save_id)] = system.get_save_data()
	SaveFile.write(slot, _snapshot)
	_busy = false


func delete_save() -> void:
	SaveFile.delete(slot)
	_snapshot = _empty_snapshot()


## Remembers the state of a room's persistent nodes before it unloads.
func store_room(room: Node) -> void:
	if _enter():
		_store_room(room)
		_busy = false


## Gives a freshly loaded room's persistent nodes their stored state.
func restore_room(room: Node) -> void:
	var stored: Variant = _snapshot.rooms.get(room.scene_file_path)
	if not stored is Dictionary:
		return
	for node in _persistent_nodes(room):
		var data: Variant = stored.get(String(room.get_path_to(node)))
		if data is Dictionary:
			node.apply_save_data(data)


func _store_room(room: Node) -> void:
	var stored := {}
	for node in _persistent_nodes(room):
		stored[String(room.get_path_to(node))] = node.get_save_data()
	_snapshot.rooms[room.scene_file_path] = stored


func _persistent_nodes(room: Node) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in room.get_tree().get_nodes_in_group(PERSISTENT_GROUP):
		if room.is_ancestor_of(node):
			nodes.append(node)
	return nodes


## Guards against saving from inside another save.
func _enter() -> bool:
	if _busy:
		push_error("SaveManager: save requested while another one is running")
		return false
	_busy = true
	return true


func _empty_snapshot() -> Dictionary:
	return {"version": FORMAT_VERSION, "global": {}, "rooms": {}}
