class_name Crow
extends Enemy
## A flying enemy. It ignores gravity while alive, flies over gaps and
## through one-way platforms, and reaches the player at any height.
## Dead, it falls like any other body.
##
## Its states (Hover, Pursue, Swoop) steer with `fly_toward()`. The shared
## Hurt, Stunned and Dead states work as they are: `apply_gravity()` only
## slows its vertical drift while it is alive.

@export_group("Flight")
## How far left and right of its spawn point it hovers while patrolling (px).
@export var patrol_distance := 64.0
## Up-and-down bob while hovering (px).
@export var bob_height := 6.0
## Bob cycles per second.
@export var bob_speed := 1.2
## While pursuing, it keeps this far above the player's feet (px).
@export var hover_height := 56.0
## While pursuing, it keeps this far to the side of the player (px).
@export var hover_distance := 40.0


## Alive, it hangs in the air: vertical speed eases to 0. Dead, it falls.
func apply_gravity(delta: float) -> void:
	if health.is_dead():
		super(delta)
	else:
		velocity.y = move_toward(velocity.y, 0.0, friction * delta)


## Steers towards `point` at up to `speed`, easing in with `acceleration`.
func fly_toward(point: Vector2, speed: float, delta: float) -> void:
	var to_point := point - global_position
	var wanted := to_point.limit_length(speed)
	# Slow down on arrival instead of overshooting.
	if to_point.length() < 16.0:
		wanted *= to_point.length() / 16.0
	velocity = velocity.move_toward(wanted, acceleration * delta)


## Only a wall stops it. It has no ledges to worry about.
func is_path_blocked() -> bool:
	return is_on_wall() and signf(get_wall_normal().x) == -facing


## It flies, so any living player in range can be reached.
func can_reach_target() -> bool:
	return _has_live_target()


## Straight-line distance to the player's body, not just horizontal.
func is_target_in_attack_range() -> bool:
	if not _has_live_target():
		return false
	return global_position.distance_to(target_point()) <= attack_range


## Where it rests and hovers around while patrolling.
func home_position() -> Vector2:
	return _spawn_position


## The point above and to the side of the player it hovers at while
## pursuing, on the side it is already on.
func pursuit_point() -> Vector2:
	var side := signf(global_position.x - _target.global_position.x)
	if side == 0.0:
		side = float(-facing)
	return _target.global_position + Vector2(side * hover_distance, -hover_height)
