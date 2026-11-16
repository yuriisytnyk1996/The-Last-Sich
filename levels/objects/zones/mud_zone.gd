@tool
class_name MudZone
extends AreaEffect
## Deep mud: slows running and lowers jumps while the player is in it.
## Lay it on top of the floor, a little taller than the feet (16 to 24 px),
## so jumping out of it ends the effect.

## Fraction of the run speed kept.
@export_range(0.1, 1.0) var speed_multiplier := 0.5
## Fraction of the jump height kept.
@export_range(0.1, 1.0) var jump_multiplier := 0.5


func speed_factor() -> float:
	return speed_multiplier


func jump_factor() -> float:
	return jump_multiplier


func _get_color() -> Color:
	return Color(0.35, 0.24, 0.12, 0.75)
