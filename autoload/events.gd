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
