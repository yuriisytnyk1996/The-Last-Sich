extends Node
## Global signal bus (autoload "Events").
##
## Systems that shouldn't know about each other talk through here.
## Example: a kill zone emits `Events.player_died`, and the room, HUD,
## audio and save system can all react without referencing each other.
## Add new signals here as the game grows.

@warning_ignore("unused_signal")
signal player_died
