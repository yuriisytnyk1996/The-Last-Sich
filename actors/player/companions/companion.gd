class_name Companion
extends Node2D
## Base for helpers that float beside the player, summoned by an item
## (`SummonEffect`): the sworn brother, the falcons, the wandering light.
##
## `follow()` is called before it is added and `dismiss()` when the effect
## stops: it fades out over `fade_time`, then frees itself. It lives under
## the `World`, so it goes into the next room with the player;
## `glide_to()` jumps it to its target when that is more than
## `snap_distance` away (a room change, travel). A subclass moves itself
## in `_physics_process()` and does its own cleanup in `_on_dismiss()`.

## Farther than this from its target (px), it jumps there.
@export var snap_distance := 160.0
## Seconds to fade out when dismissed.
@export var fade_time := 0.3

var player: Player
var _dismissed := false


## Call before adding it to the tree.
func follow(summoner: Player) -> void:
	player = summoner
	position = player.global_position


func dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	_on_dismiss()
	if not is_inside_tree():
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)


func is_dismissed() -> bool:
	return _dismissed


## The player is gone (back to the main menu): frees it and returns true.
func lost_player() -> bool:
	if is_instance_valid(player):
		return false
	queue_free()
	return true


## Eases towards `target` (higher `speed` is tighter). Returns true when it
## was too far and jumped there instead.
func glide_to(target: Vector2, speed: float, delta: float) -> bool:
	if global_position.distance_to(target) > snap_distance:
		global_position = target
		reset_physics_interpolation()
		return true
	global_position = global_position.lerp(target, minf(speed * delta, 1.0))
	return false


func _on_dismiss() -> void:
	pass
