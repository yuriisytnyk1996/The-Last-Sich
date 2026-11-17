extends EnemyAttackState
## The crow's attack: rears up through the wind-up while tracking the
## player, locks its aim `aim_lock` before the dive, then swoops in a
## straight line with its talons out. The dive ends early when it hits
## terrain. Recovery is a slow climb back up, the opening to hit it.

## Speed of the dive (px/s).
@export var swoop_speed := 230.0
## Seconds before the dive when the aim stops following the player.
@export var aim_lock := 0.15
## Upward drift during the wind-up and recovery (px/s).
@export var rise_speed := 25.0

var _direction := Vector2.DOWN


func enter(previous_state: StringName) -> void:
	super(previous_state)
	_aim()


func move(delta: float) -> void:
	match _phase:
		Phase.STARTUP:
			if _time_left > aim_lock:
				_aim()
			_drift_up(delta)
		Phase.ACTIVE:
			enemy.velocity = _direction * swoop_speed
		Phase.RECOVERY:
			_drift_up(delta)


func physics_update(delta: float) -> void:
	super(delta)
	# Hit the ground or a wall: the dive is over.
	if _phase == Phase.ACTIVE and enemy.get_slide_collision_count() > 0:
		_time_left = 0.0


func _aim() -> void:
	if enemy.can_track_target():
		_direction = enemy.global_position.direction_to(enemy.target_point())
		enemy.face_target()


func _drift_up(delta: float) -> void:
	var wanted := Vector2(0.0, -rise_speed)
	enemy.velocity = enemy.velocity.move_toward(wanted, enemy.acceleration * delta)
