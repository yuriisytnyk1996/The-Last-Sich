class_name World
extends Node2D
## The main scene. Owns the player, the HUD and the current room, and
## swaps rooms when the player goes through a `RoomExit`.
##
## The player lives here rather than in each room, so health and state
## carry over between rooms.

@export_file("*.tscn") var start_room := "res://levels/rooms/test_room.tscn"

var room: Room
var _changing := false

@onready var room_holder: Node2D = $RoomHolder
@onready var player: Player = $Player
@onready var fade: ScreenFade = $ScreenFade


func _ready() -> void:
	Events.room_change_requested.connect(_on_room_change_requested)
	_load_room(start_room, &"")


func _on_room_change_requested(room_path: String, exit_name: StringName) -> void:
	if _changing:
		return
	_changing = true
	# Freeze everything, so nothing hits the player while the screen is dark.
	# The player keeps their velocity and state and carries on afterwards.
	get_tree().paused = true
	await fade.fade_out()
	_load_room(room_path, exit_name)
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
