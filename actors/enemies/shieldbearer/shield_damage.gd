class_name ShieldDamage
extends EnemyDamage
## The shieldbearer's hit handling: a raised shield blocks every hit from
## the front, unless it is HEAVY.
##
## - From the front, LIGHT or NORMAL: blocked by the hurtbox's `guard`. No
##   damage, no stagger, the attacker's hit doesn't land (no spirit), and
##   the shield flashes. Projectiles stop on it.
## - From the front, HEAVY: the hit lands and **breaks the guard**: the
##   enemy is stunned for `stun_time` with its shield down, like a parry.
## - From behind: the shield doesn't cover the back, so the hit lands and
##   staggers as usual (and counts towards poise).
##
## "Front" is the side the hit pushes from (`Hitbox.push_direction()`),
## not where the hitbox is, so a swing from right behind the enemy that
## reaches past its middle still counts as from behind.
##
## The shield is only raised while patrolling, chasing or attacking. Hurt,
## Stunned and Dead lower it.

const GUARD_STATES: Array[StringName] = [EnemyState.PATROL, EnemyState.CHASE, EnemyState.ATTACK]

@export_group("Shield")
## Placeholder shown while the shield is raised. Optional.
@export var shield: CanvasItem
## Flash shown on the shield when it blocks. Optional.
@export var spark: CanvasItem
## Seconds the block flash stays.
@export var spark_time := 0.08

var _breaking := false
var _spark_left := 0.0


func _ready() -> void:
	super()
	await owner.ready
	enemy.hurtbox.guard = _blocks


func _physics_process(delta: float) -> void:
	super(delta)
	if shield:
		shield.visible = is_guarding()
	_spark_left = maxf(_spark_left - delta, 0.0)
	if spark:
		spark.visible = _spark_left > 0.0


func is_guarding() -> bool:
	var state := enemy.state_machine.state
	return state != null and state.name in GUARD_STATES


## The hurtbox's guard: true blocks the hit.
func _blocks(hitbox: Hitbox) -> bool:
	if not is_guarding() or not _is_from_front(hitbox):
		return false
	if hitbox.reaction == Hitbox.Reaction.HEAVY:
		_breaking = true
		return false
	_spark_left = spark_time
	return true


func _is_from_front(hitbox: Hitbox) -> bool:
	return hitbox.push_direction(enemy.global_position) == float(-enemy.facing)


func _on_hurt(hitbox: Hitbox) -> void:
	if not _breaking:
		super(hitbox)
		return
	_breaking = false
	_since_hit = 0.0
	knockback = hitbox.push_direction(enemy.global_position) * stun_knockback
	enemy.state_machine.transition_to(EnemyState.STUNNED)
