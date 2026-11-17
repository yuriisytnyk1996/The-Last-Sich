class_name UnlockEffect
extends ItemEffect
## Gives the player a traversal unlock (see `PlayerUnlocks`) while the
## effect runs, such as a keepsake that shows hidden platforms. Use a
## lasting trigger: OWNED or EQUIPPED.

## One of the `PlayerUnlocks` constants.
@export_enum("reveal_platforms", "rest_travel", "rest_spirit") var unlock := "reveal_platforms"


func start(player: Player, source: StringName) -> void:
	player.unlocks.grant(StringName(unlock), source)


func stop(player: Player, source: StringName) -> void:
	player.unlocks.revoke(StringName(unlock), source)
