class_name PlayerDamage
extends Node
## How the player reacts to being hit, and the tuning for it.
##
## Picks the knockback and stagger length from the hit's reaction, then
## enters Hurt (or Dead). Light hits only flash and grant invincibility.
## Invincibility covers the whole Hurt state and lasts `invincibility_time`
## after it ends; the Hurt state sets that up.

@export_group("Hurt")
## Seconds without control after a normal hit.
@export var hurt_duration := 0.3
## Speed away from the hit (x) and upward pop (y), in px/s.
@export var hurt_knockback := Vector2(160.0, 140.0)
@export var heavy_hurt_duration := 0.5
@export var heavy_knockback := Vector2(240.0, 180.0)

@export_group("Invincibility")
## Immunity after Hurt ends (s). A light hit gives this from the hit.
@export var invincibility_time := 0.5

@export_group("Death")
## Seconds the body lies still before the room respawns the player.
@export var death_delay := 1.0

## Resolved for the current hit, read by the Hurt state.
var knockback := Vector2.ZERO
var stagger_time := 0.0

@onready var player := owner as Player


func _ready() -> void:
	await owner.ready
	player.hurtbox.invincibility_time = invincibility_time
	player.hurtbox.hurt.connect(_on_hurt)
	player.health.died.connect(_on_died)
	player.health.health_changed.connect(Events.player_health_changed.emit)
	# Deferred: the HUD may come after the player in the tree and isn't ready yet.
	_announce_health.call_deferred()


## Full health, no invincibility. Called on respawn.
func reset() -> void:
	player.health.reset()
	player.hurtbox.clear_invincibility()


func _announce_health() -> void:
	Events.player_health_changed.emit(player.health.current, player.health.max_health)


func _on_hurt(hitbox: Hitbox) -> void:
	if hitbox.reaction == Hitbox.Reaction.LIGHT:
		return
	var heavy := hitbox.reaction == Hitbox.Reaction.HEAVY
	var push := heavy_knockback if heavy else hurt_knockback
	var direction := _push_direction(hitbox)
	knockback = Vector2(direction * push.x, -push.y)
	stagger_time = heavy_hurt_duration if heavy else hurt_duration
	player.set_facing(-direction)
	player.state_machine.transition_to(PlayerState.HURT)


func _on_died() -> void:
	player.state_machine.transition_to(PlayerState.DEAD)


## 1 pushes right, -1 left. Follows the hitbox's knockback; a hitbox that
## pushes straight up (spikes) pushes away from its centre instead.
func _push_direction(hitbox: Hitbox) -> float:
	var direction := signf(hitbox.get_knockback().x)
	if direction == 0.0:
		direction = signf(player.global_position.x - hitbox.global_position.x)
	return direction if direction != 0.0 else float(-player.facing)
