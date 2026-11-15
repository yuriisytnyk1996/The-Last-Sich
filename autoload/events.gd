extends Node
## Global signal bus (autoload "Events").
##
## Systems that shouldn't know about each other talk through here.
## Example: a kill zone emits `Events.player_died`, and the room, HUD,
## audio and save system can all react without referencing each other.
## Add new signals here as the game grows.

@warning_ignore("unused_signal")
signal player_died

## Shake the active camera. `trauma` is 0 to 1; requests add up.
@warning_ignore("unused_signal")
signal camera_shake_requested(trauma: float)

## The player's health changed (also sent once when the player spawns).
## The HUD listens to this instead of holding a reference to the player.
@warning_ignore("unused_signal")
signal player_health_changed(current: int, maximum: int)

## The player used a rest point. The world makes it the respawn point.
@warning_ignore("unused_signal")
signal rested(rest_point: Node2D)

## The player walked through a `RoomExit`. The world fades out, loads
## `room_path` and places the player at the exit named `exit_name` there.
@warning_ignore("unused_signal")
signal room_change_requested(room_path: String, exit_name: StringName)
