class_name DripTrap
extends Turret
## A spout in the ceiling that drips burning tar. Every `fire_interval` a
## drop swells under it for `warn_time` (the `Warning` child grows from a
## bead to a full drop), then lets go and falls (`LiquidDrop`). A row of
## spouts with different `offset`s makes a curtain the player times their
## run through. `trigger_range` keeps a spout quiet while the player is far.
##
## Place the origin on the ceiling's underside. Don't rotate it: drops
## always fall straight down.

## Scale of the bead when it starts to swell.
const BEAD_START := 0.3


func _process(_delta: float) -> void:
	warning.scale = Vector2.ONE * lerpf(BEAD_START, 1.0, warn_fraction())
