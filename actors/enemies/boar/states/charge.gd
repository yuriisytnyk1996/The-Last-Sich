extends EnemyAttackState
## The boar's attack: paws the ground through the wind-up, then charges
## straight ahead at `charge_speed` for up to `active` seconds, tusks out.
## It can't turn once it starts, so the player gets out of the way by
## jumping over it or onto something.
##
## - **Wall:** it crashes, bounces back at `crash_bounce` and is dazed
##   (Stunned, `EnemyDamage.stun_time`), with a camera shake.
## - **Ledge:** it digs in and stops at the edge, going straight to recovery.
## - **Nothing:** it runs out of breath after `active` and skids to a stop.
##
## Recovery is the skid, the opening to punish.

## Running speed of the charge (px/s).
@export var charge_speed := 220.0
## How fast it reaches charge speed (px/s²).
@export var charge_acceleration := 900.0
## Speed it bounces back off a wall (px/s).
@export var crash_bounce := 90.0
## Camera shake (trauma) when it crashes into a wall.
@export var crash_shake := 0.35
## Friction during the skid after a charge (px/s²). Lower slides further.
@export var skid_friction := 350.0


func move(delta: float) -> void:
	match _phase:
		Phase.STARTUP:
			enemy.stop(delta)
		Phase.ACTIVE:
			var wanted := enemy.facing * charge_speed
			enemy.velocity.x = move_toward(enemy.velocity.x, wanted, charge_acceleration * delta)
		Phase.RECOVERY:
			enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, skid_friction * delta)


func physics_update(delta: float) -> void:
	super(delta)
	if _phase == Phase.RECOVERY and enemy.is_path_blocked():
		# Never skid off a ledge.
		enemy.velocity.x = 0.0
	if _phase != Phase.ACTIVE:
		return
	if enemy.is_on_wall() and signf(enemy.get_wall_normal().x) == -enemy.facing:
		_crash()
	elif enemy.is_path_blocked():
		# A ledge: stop dead at the edge instead of skidding off.
		enemy.velocity.x = 0.0
		_time_left = 0.0


func _crash() -> void:
	enemy.damage.knockback = -enemy.facing * crash_bounce
	Events.camera_shake_requested.emit(crash_shake)
	finished.emit(STUNNED)
