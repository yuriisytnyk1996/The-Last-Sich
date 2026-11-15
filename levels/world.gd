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

@export_file("*.tscn") var start_room := "res://levels/rooms/test_room.tscn"

var room: Room
var _changing := false
## The last rest point used: its room and its path inside that room.
var _rest_room := ""
var _rest_path: NodePath

@onready var room_holder: Node2D = $RoomHolder
@onready var player: Player = $Player
@onready var fade: ScreenFade = $ScreenFade


func _ready() -> void:
	Events.room_change_requested.connect(_on_room_change_requested)
	Events.rested.connect(_on_rested)
	Events.player_died.connect(_on_player_died)
	_load_room(start_room, &"")


func _on_room_change_requested(room_path: String, exit_name: StringName) -> void:
	_transition(_load_room.bind(room_path, exit_name))


func _on_rested(rest_point: Node2D) -> void:
	_rest_room = room.scene_file_path
	_rest_path = room.get_path_to(rest_point)


func _on_player_died() -> void:
	if _rest_room == "":
		room.respawn_player()
	else:
		_transition(_respawn_at_rest_point)


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
		room_holder.remove_child(room)
		room.queue_free()
	room = (load(room_path) as PackedScene).instantiate() as Room
	room_holder.add_child(room)
	room.enter(player, exit_name)
	player.camera.reset_smoothing.call_deferred()
	var rest_point := _current_rest_point()
	if rest_point:
		rest_point.set_lit(true)


## Always reloads the room, so its enemies start fresh.
func _respawn_at_rest_point() -> void:
	_load_room(_rest_room, &"")
	player.respawn(_current_rest_point().global_position)


## The last rest point used, if it is in the current room.
func _current_rest_point() -> RestPoint:
	if room.scene_file_path != _rest_room:
		return null
	return room.get_node_or_null(_rest_path) as RestPoint
