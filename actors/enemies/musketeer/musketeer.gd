class_name Musketeer
extends Enemy
## A ranged enemy: keeps its distance, aims and fires a musket ball, then
## reloads. The extra tuning and helpers its states use live here.

@export_group("Distance")
## Closer than this, it backs away from the player (px).
@export var retreat_range := 64.0
## Speed while backing away, slower than the player can run (px/s).
@export var retreat_speed := 45.0

@onready var back_probe: RayCast2D = $Visual/BackProbe


## Steps backwards, still facing the player.
func retreat(delta: float) -> void:
	velocity.x = move_toward(velocity.x, -facing * retreat_speed, acceleration * delta)


## A wall or a drop right behind: it won't back off a ledge.
func is_retreat_blocked() -> bool:
	if is_on_wall() and signf(get_wall_normal().x) == facing:
		return true
	return is_on_floor() and not back_probe.is_colliding()


func is_target_too_close() -> bool:
	return can_reach_target() and absf(_target_offset().x) < retreat_range
