extends PlayerAttackState
## Horizontal slash in front of the player, on the ground or in the air.
## On the ground the player is planted, but pushing the other way turns them
## around mid-swing (the hitbox turns with them). In the air, facing stays
## locked.

## How far the stick must point the other way to turn around.
const TURN_THRESHOLD := 0.2


func move(delta: float) -> void:
	super.move(delta)
	if not _started_on_floor:
		return
	var axis := player.get_move_axis()
	if absf(axis) > TURN_THRESHOLD and signf(axis) != player.facing:
		player.set_facing(axis)
