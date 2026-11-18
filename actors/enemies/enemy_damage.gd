class_name EnemyDamage
extends Node
## How an enemy reacts to being hit, and the tuning for it.
##
## LIGHT hits only flash. NORMAL and HEAVY hits turn the enemy towards the
## attacker and stagger it into Hurt, unless the current state can't be
## interrupted (an attack whose blade is already out).
##
## Poise: after `max_staggers` staggers in a row the enemy stops flinching
## and strikes back as soon as the player is in reach. The count resets
## after `poise_recovery` without being hit, or when an attack finishes.
##
## A parried attack stuns the enemy for `stun_time` (see `stun()`).
##
## Executions: a lethal hit on a stunned enemy, a lethal stunning hit, a
## lethal HEAVY hit that catches it winding up an attack, or a lethal HEAVY
## hit from a hitbox with `executes` on leaves it at 1 health in its
## Executable state instead of killing it. Only enemies whose scene has an
## Executable state, and only on the ground.

@export_group("Hurt")
## Seconds without control after a normal hit.
@export var hurt_duration := 0.25
## Speed away from the hit (px/s). Friction slows it down.
@export var hurt_knockback := 110.0
@export var heavy_hurt_duration := 0.45
@export var heavy_knockback := 180.0

@export_group("Poise")
## Off: NORMAL and HEAVY hits never stagger it (bosses). A parry still stuns.
@export var flinches := true
## Staggers in a row before the enemy stops flinching. 0 never flinches.
@export var max_staggers := 3
## Seconds without being hit before the stagger count resets.
@export var poise_recovery := 1.5

@export_group("Stun")
## Seconds an enemy stays stunned after its attack is parried.
@export var stun_time := 1.0
## Speed it is pushed away from the player when parried (px/s).
@export var stun_knockback := 100.0

@export_group("Execution")
## Seconds an executable enemy waits for the finisher before getting up.
@export var execution_window := 4.0
## Seconds after going down when hits don't land, so the swing that
## brought it down doesn't finish it off at once.
@export var execution_safe_time := 0.5
## Part of max health it has when it gets up again.
@export_range(0.0, 1.0) var recover_health := 0.5

@export_group("Death")
## Seconds the body stays before it starts fading.
@export var corpse_time := 0.5
## Seconds the fade-out takes.
@export var fade_time := 0.4
## Once killed, stays dead when the player leaves the room and comes back,
## until they rest or die. Off: back every time the room loads.
@export var stays_dead := true
## Currency the player earns for the kill.
@export var currency_reward := 10

## Resolved for the current hit, read by the Hurt state. Signed x speed.
var knockback := 0.0
var stagger_time := 0.0

var _staggers := 0
## Laid dead on room load: killed earlier, so no reward this time.
var _lying_dead := false
var _since_hit := 0.0

@onready var enemy := owner as Enemy


func _ready() -> void:
	await owner.ready
	enemy.hurtbox.hurt.connect(_on_hurt)
	enemy.health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_since_hit += delta
	if _since_hit >= poise_recovery:
		_staggers = 0


## Full health, full poise, no invincibility. Called by `Enemy.reset()`.
func reset() -> void:
	enemy.health.reset()
	enemy.hurtbox.clear_invincibility()
	reset_poise()
	_lying_dead = false


## Already dead when the room loads: killed earlier and not back yet.
## Skips the fade. `Enemy.reset()` brings it back as usual.
func lie_dead() -> void:
	_lying_dead = true
	enemy.health.kill()
	enemy.modulate.a = 0.0


## Called when an attack finishes, so the enemy can be staggered again.
func reset_poise() -> void:
	_staggers = 0


func is_poise_broken() -> bool:
	return _staggers >= max_staggers


func _on_hurt(hitbox: Hitbox) -> void:
	if not flinches:
		return
	if _becomes_executable(hitbox):
		enemy.health.spare_next_lethal = true
		enemy.state_machine.transition_to(EnemyState.EXECUTABLE)
		return
	if hitbox.stuns:
		if not enemy.health.is_dead():
			stun_from(hitbox.global_position)
		return
	if hitbox.reaction == Hitbox.Reaction.LIGHT:
		return
	var state := enemy.state_machine.state as EnemyState
	if state and not state.can_be_staggered():
		return

	_since_hit = 0.0
	var direction := hitbox.push_direction(enemy.global_position)
	if direction == 0.0:
		direction = float(-enemy.facing)
	if is_poise_broken():
		_strike_back(direction)
		return
	_staggers += 1

	var heavy := hitbox.reaction == Hitbox.Reaction.HEAVY
	knockback = direction * (heavy_knockback if heavy else hurt_knockback)
	stagger_time = heavy_hurt_duration if heavy else hurt_duration
	enemy.set_facing(-direction)
	enemy.state_machine.transition_to(EnemyState.HURT)


## This lethal hit brings the enemy to its knees instead of killing it.
## Runs before the damage is applied (`Hurtbox` emits `hurt` first).
func _becomes_executable(hitbox: Hitbox) -> bool:
	if not enemy.state_machine.has_node(NodePath(EnemyState.EXECUTABLE)):
		return false
	if not enemy.is_on_floor() or enemy.health.damage_from(hitbox) < enemy.health.current:
		return false
	var state := enemy.state_machine.state as EnemyState
	if state.name == EnemyState.STUNNED or hitbox.stuns:
		return true
	var heavy := hitbox.reaction == Hitbox.Reaction.HEAVY
	if heavy and hitbox.executes:
		return true
	return heavy and state.name == EnemyState.ATTACK and state.can_be_staggered()


## Shrugs the hit off: faces the attacker and, if they're in reach,
## attacks right away, cooldown or not. Hits during that attack's wind-up
## don't interrupt it, because poise stays broken until it finishes.
func _strike_back(direction: float) -> void:
	enemy.set_facing(-direction)
	var state := enemy.state_machine.state.name
	if state != EnemyState.ATTACK and enemy.is_target_in_attack_range():
		enemy.state_machine.transition_to(EnemyState.ATTACK)


## Its attack was parried by `hurtbox`: pushed back and helpless for a moment.
func stun(hurtbox: Hurtbox) -> void:
	stun_from(hurtbox.global_position)


## Stunned by something at `from` (a parry, a stunning hit): pushed away
## from it and helpless for `stun_time`.
func stun_from(from: Vector2) -> void:
	var direction := signf(enemy.global_position.x - from.x)
	if direction == 0.0:
		direction = float(-enemy.facing)
	knockback = direction * stun_knockback
	enemy.state_machine.transition_to(EnemyState.STUNNED)


func _on_died() -> void:
	enemy.state_machine.transition_to(EnemyState.DEAD)
	if not _lying_dead:
		Events.currency_earned.emit(currency_reward)
		Events.enemy_killed.emit()
