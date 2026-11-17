extends EnemyState
## The crow's Chase: flies to a point above and to the side of the player
## (`Crow.pursuit_point()`) and swoops once it can see the player within
## `attack_range` and is off cooldown.
##
## Walls and solid ceilings stop it, so a player under cover breaks its
## line of sight. It gives up and flies home after `lose_sight_time` out of
## sight, or once the player is further than `lose_range`.

var _unseen_time := 0.0

@onready var crow := owner as Crow


func enter(_previous_state: StringName) -> void:
	_unseen_time = 0.0


func physics_update(delta: float) -> void:
	crow.face_target()
	if crow.can_track_target():
		crow.fly_toward(crow.pursuit_point(), crow.chase_speed, delta)
	crow.move_and_slide()

	var sees := crow.can_see_target()
	_unseen_time = 0.0 if sees else _unseen_time + delta
	if not crow.can_track_target() or _unseen_time >= crow.lose_sight_time:
		finished.emit(PATROL)
	elif sees and crow.is_target_in_attack_range() and crow.can_attack():
		finished.emit(ATTACK)
