class_name EnemyDamage
extends Node
## How an enemy reacts to being hit, and the tuning for it.
##
## LIGHT hits only flash. NORMAL and HEAVY hits turn the enemy towards the
## attacker and stagger it into Hurt, unless the current state can't be
## interrupted (an attack whose blade is already out).

@export_group("Hurt")
## Seconds without control after a normal hit.
@export var hurt_duration := 0.25
## Speed away from the hit (px/s). Friction slows it down.
@export var hurt_knockback := 110.0
@export var heavy_hurt_duration := 0.45
@export var heavy_knockback := 180.0

@export_group("Death")
## Seconds the body stays before it starts fading.
@export var corpse_time := 0.5
## Seconds the fade-out takes.
@export var fade_time := 0.4

## Resolved for the current hit, read by the Hurt state. Signed x speed.
var knockback := 0.0
var stagger_time := 0.0

@onready var enemy := owner as Enemy


func _ready() -> void:
	await owner.ready
	enemy.hurtbox.hurt.connect(_on_hurt)
	enemy.health.died.connect(_on_died)


## Full health, no invincibility. Called by `Enemy.reset()`.
func reset() -> void:
	enemy.health.reset()
	enemy.hurtbox.clear_invincibility()


func _on_hurt(hitbox: Hitbox) -> void:
	if hitbox.reaction == Hitbox.Reaction.LIGHT:
		return
	var state := enemy.state_machine.state as EnemyState
	if state and not state.can_be_staggered():
		return

	var heavy := hitbox.reaction == Hitbox.Reaction.HEAVY
	var direction := hitbox.push_direction(enemy.global_position)
	if direction == 0.0:
		direction = float(-enemy.facing)
	knockback = direction * (heavy_knockback if heavy else hurt_knockback)
	stagger_time = heavy_hurt_duration if heavy else hurt_duration
	enemy.set_facing(-direction)
	enemy.state_machine.transition_to(EnemyState.HURT)


func _on_died() -> void:
	enemy.state_machine.transition_to(EnemyState.DEAD)
