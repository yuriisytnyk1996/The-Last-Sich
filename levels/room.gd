class_name Room
extends Node2D
## A level room: camera bounds, pits, exits and respawning.
##
## The `World` scene owns the player and calls `enter()` after adding the
## room. When the player dies, they respawn where they entered this room
## and every enemy in it resets.

## The playable area. The camera never shows anything outside it.
@export var bounds := Rect2i(0, 0, 1280, 360)

var player: Player
var _respawn_position := Vector2.ZERO

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var kill_zone: Area2D = get_node_or_null(^"KillZone")
@onready var exits: Node = get_node_or_null(^"Exits")


func _ready() -> void:
	if kill_zone:
		kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	Events.player_died.connect(_on_player_died)


## Hands the player to this room. Returns where the player should stand:
## the landing of the exit named `exit_name`, or `SpawnPoint` when empty.
func enter(entering_player: Player, exit_name: StringName) -> Vector2:
	player = entering_player
	player.set_camera_limits(bounds)
	_respawn_position = spawn_point.global_position
	var exit := _find_exit(exit_name)
	if exit:
		_respawn_position = exit.landing.global_position
	elif exit_name != &"":
		push_warning("Room %s has no exit named %s" % [name, exit_name])
	return _respawn_position


func _find_exit(exit_name: StringName) -> RoomExit:
	if exit_name == &"" or exits == null:
		return null
	return exits.get_node_or_null(NodePath(exit_name)) as RoomExit


func _on_kill_zone_body_entered(body: Node2D) -> void:
	# A pit is instant death, whatever health is left. The Dead state
	# takes it from there. Deferred: never change physics state inside a
	# physics callback.
	if body is Player:
		(body as Player).health.kill.call_deferred()
	elif body is Enemy:
		(body as Enemy).health.kill.call_deferred()


func _on_player_died() -> void:
	if player == null:
		return
	player.respawn(_respawn_position)
	get_tree().call_group(&"enemies", &"reset")
