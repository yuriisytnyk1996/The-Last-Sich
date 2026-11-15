class_name Room
extends Node2D
## A level room: sets the camera bounds and respawns the player.
##
## Later, rooms can be split into Layout / Deco / Logic sub-scenes
## by instancing them as children.

## The playable area. The camera never shows anything outside it.
@export var bounds := Rect2i(0, 0, 1280, 360)

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var kill_zone: Area2D = $KillZone
@onready var player: Player = $Player


func _ready() -> void:
	player.global_position = spawn_point.global_position
	player.set_camera_limits(bounds)
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	Events.player_died.connect(_on_player_died)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		# A pit is instant death, whatever health is left. The Dead state
		# then asks for the respawn. Deferred: never change physics state
		# inside a physics callback.
		(body as Player).health.kill.call_deferred()


func _on_player_died() -> void:
	player.respawn(spawn_point.global_position)
