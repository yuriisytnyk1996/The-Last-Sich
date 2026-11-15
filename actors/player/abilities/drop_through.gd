class_name PlayerDropThrough
extends Node
## Down + jump on a one-way platform drops the player through it.
##
## One-way tiles sit on the `platforms` layer, so dropping just switches
## that layer off in the player's mask for `drop_through_time`, then back on.

## How long the platforms layer stays off, enough to fall clear of the plank.
@export var drop_through_time := 0.25

var _time_left := 0.0

@onready var player := owner as Player


func _physics_process(delta: float) -> void:
	if _time_left > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			player.set_platforms_enabled(true)


## Down + jump while standing only on one-way platforms (no solid floor below).
func wants() -> bool:
	if not (player.wants_jump() and player.is_on_floor()):
		return false
	if player.get_vertical_axis() < player.attack_vertical_threshold:
		return false
	player.set_platforms_enabled(false)
	var on_solid := player.test_move(player.global_transform, Vector2(0.0, 1.0))
	player.set_platforms_enabled(true)
	return not on_solid


func start() -> void:
	player.consume_jump()
	player.set_platforms_enabled(false)
	_time_left = drop_through_time


func reset() -> void:
	_time_left = 0.0
	player.set_platforms_enabled(true)
