class_name World
extends Node2D
## The main scene. Owns the player, the HUD and the current room, swaps
## rooms when the player goes through a `RoomExit`, and brings the player
## back after death.
##
## The player lives here rather than in each room, so health and state
## carry over between rooms. After a rest point has been used, death
## respawns the player there, loading its room if needed. Before that, the
## current room respawns them where they entered it.
##
## The world is a global save system (see `SaveManager`): it saves the
## last rest point, and on start it loads the save and wakes the player
## there. Resting writes the save to disk, and so does dying, so quitting
## can't undo the death penalty (see `DeathPenalty`). A new game saves at
## once, so its slot shows as taken on the slot-select screen.
##
## The duma of return (`Events.return_requested`) fades out and puts the
## player back at the last rest point, without healing them.
##
## Travel between rest points: after a rest with travel unlocked it opens
## the kneel prompt, and on `Events.travel_requested` it fades out, loads
## the chosen rest point's room and makes that rest point the respawn point.

@export_file("*.tscn") var start_room := "res://levels/rooms/test_room.tscn"

var save_id := &"world"

var room: Room
var _killed := KilledEnemies.new()
var _changing := false
## The last rest point used: its room and its path inside that room.
var _rest_room := ""
var _rest_path: NodePath

@onready var room_holder: Node2D = $RoomHolder
@onready var player: Player = $Player
@onready var fade: ScreenFade = $ScreenFade
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var death_penalty: DeathPenalty = $DeathPenalty
@onready var world_map: WorldMap = $WorldMap


func _ready() -> void:
	Events.room_change_requested.connect(_on_room_change_requested)
	Events.rested.connect(_on_rested)
	Events.player_died.connect(_on_player_died)
	Events.travel_offered.connect(pause_menu.open_kneel)
	Events.travel_requested.connect(_on_travel_requested)
	Events.return_requested.connect(_on_return_requested)
	SaveManager.register(self)
	if SaveManager.load_game() and ResourceLoader.exists(_rest_room):
		_respawn_at_rest_point()
	else:
		_rest_room = ""
		_load_room(start_room, &"")
		SaveManager.save_game(room)


## Runs only while the tree isn't paused, so the pause menu can't open
## during a room transition or while it is already open.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		pause_menu.open_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		pause_menu.open_inventory()
		get_viewport().set_input_as_handled()


func get_save_data() -> Dictionary:
	var zone := room.map_zone if room else ""
	return {"rest_room": _rest_room, "rest_path": String(_rest_path), "zone": zone}


func apply_save_data(data: Dictionary) -> void:
	_rest_room = str(data.get("rest_room", ""))
	_rest_path = NodePath(str(data.get("rest_path", "")))


func _on_room_change_requested(room_path: String, exit_name: StringName) -> void:
	_transition(_load_room.bind(room_path, exit_name))


func _on_rested(rest_point: Node2D) -> void:
	_rest_room = room.scene_file_path
	_rest_path = room.get_path_to(rest_point)
	_killed.clear()
	SaveManager.save_game(room)


func _on_travel_requested(room_path: String, cell: Vector2i) -> void:
	pause_menu.close()
	# The menu unpauses the tree one frame after closing. Waiting that frame
	# first keeps the transition's pause from being undone mid-fade.
	await get_tree().process_frame
	_transition(_travel_to.bind(room_path, cell))


## Loads `room_path` and puts the player on its rest point at map `cell`,
## which becomes the respawn point (lit and saved, see `_on_rested`).
func _travel_to(room_path: String, cell: Vector2i) -> void:
	_load_room(room_path, &"")
	var target := _rest_point_at(cell)
	if target == null:
		push_warning("Travel: no rest point on map cell %s in %s" % [cell, room_path])
		room.respawn_player()
		return
	player.respawn(target.global_position)
	Events.rested.emit(target)


func _on_return_requested() -> void:
	_transition(_return_to_rest_point)


## The duma of return: back to the last rest point used, loading its room,
## with health, flasks and spirit as they are. Before any rest, back to
## where the player entered the current room.
func _return_to_rest_point() -> void:
	if _rest_room == "":
		player.respawn(room.get_respawn_position(), false)
		return
	_load_room(_rest_room, &"")
	var rest_point := _current_rest_point()
	var at := rest_point.global_position if rest_point else room.get_respawn_position()
	player.respawn(at, false)


## The rest point of the current room on map `cell`, or null.
func _rest_point_at(cell: Vector2i) -> RestPoint:
	var map_room := world_map.current_room()
	for node in room.find_children("*", "Area2D", true, false):
		if node is RestPoint:
			var local := room.to_local((node as Node2D).global_position)
			if map_room.cell_at(local, world_map.cell_size) == cell:
				return node
	return null


func _on_player_died() -> void:
	_killed.clear()
	death_penalty.drop(room)
	if _rest_room == "":
		room.respawn_player()
		player.spirit.restore_after_death()
		death_penalty.place_in(room)
		SaveManager.save_game(room)
	else:
		_transition(_respawn_after_death)


func _respawn_after_death() -> void:
	_respawn_at_rest_point()
	player.spirit.restore_after_death()
	SaveManager.save_game(room)


## Freezes everything and fades to black, runs `change`, then fades back
## in. Nothing can hit the player while the screen is dark, and the player
## keeps their velocity and state. Requests during a transition are ignored.
func _transition(change: Callable) -> void:
	if _changing:
		return
	_changing = true
	get_tree().paused = true
	await fade.fade_out()
	change.call()
	_sync_player_physics()
	Events.player_arrived.emit()
	get_tree().paused = false
	await fade.fade_in()
	_changing = false


## Puts the player's body where they now are in the physics server at
## once. A moved kinematic body only reaches the server on the next step,
## so the new room's areas (a boss trigger) would first see the player
## where they were before, such as the spot where they died.
func _sync_player_physics() -> void:
	var rid := player.get_rid()
	PhysicsServer2D.body_set_mode(rid, PhysicsServer2D.BODY_MODE_STATIC)
	PhysicsServer2D.body_set_state(
		rid, PhysicsServer2D.BODY_STATE_TRANSFORM, player.global_transform
	)
	PhysicsServer2D.body_set_mode(rid, PhysicsServer2D.BODY_MODE_KINEMATIC)


func _load_room(room_path: String, exit_name: StringName) -> void:
	if room:
		world_map.refresh()
		SaveManager.store_room(room)
		room_holder.remove_child(room)
		room.queue_free()
	room = (load(room_path) as PackedScene).instantiate() as Room
	room_holder.add_child(room)
	SaveManager.restore_room(room)
	_killed.watch(room)
	room.enter(player, exit_name)
	# A running duma goes on into the new room; delayed attacks don't.
	player.dumas.drop_pending()
	player.safe_ground.enter_room(room.scene_file_path)
	death_penalty.place_in(room)
	world_map.enter_room(room)
	Music.set_room_music(room.music)
	# Placed by the room or an exit: a teleport, not movement.
	player.reset_physics_interpolation()
	player.camera.reset_smoothing.call_deferred()
	var rest_point := _current_rest_point()
	if rest_point:
		rest_point.set_lit(true)


## Always reloads the room, so its enemies start fresh.
func _respawn_at_rest_point() -> void:
	_load_room(_rest_room, &"")
	var rest_point := _current_rest_point()
	if rest_point:
		player.respawn(rest_point.global_position)
	else:
		push_warning("Rest point %s is gone from %s" % [_rest_path, _rest_room])
		room.respawn_player()


## The last rest point used, if it is in the current room.
func _current_rest_point() -> RestPoint:
	if room.scene_file_path != _rest_room:
		return null
	return room.get_node_or_null(_rest_path) as RestPoint
