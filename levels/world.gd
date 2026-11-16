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
## can't undo the death penalty (see `DeathPenalty`).

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
	SaveManager.register(self)
	if SaveManager.load_game() and ResourceLoader.exists(_rest_room):
		_respawn_at_rest_point()
	else:
		_rest_room = ""
		_load_room(start_room, &"")


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
	return {"rest_room": _rest_room, "rest_path": String(_rest_path)}


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


func _on_player_died() -> void:
	_killed.clear()
	death_penalty.drop(room)
	if _rest_room == "":
		room.respawn_player()
		death_penalty.place_in(room)
		SaveManager.save_game(room)
	else:
		_transition(_respawn_after_death)


func _respawn_after_death() -> void:
	_respawn_at_rest_point()
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
	get_tree().paused = false
	await fade.fade_in()
	_changing = false


func _load_room(room_path: String, exit_name: StringName) -> void:
	if room:
		SaveManager.store_room(room)
		room_holder.remove_child(room)
		room.queue_free()
	room = (load(room_path) as PackedScene).instantiate() as Room
	room_holder.add_child(room)
	SaveManager.restore_room(room)
	_killed.watch(room)
	room.enter(player, exit_name)
	player.safe_ground.enter_room(room.scene_file_path)
	death_penalty.place_in(room)
	world_map.enter_room(room)
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
