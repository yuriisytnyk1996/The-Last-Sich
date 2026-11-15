class_name Hurtbox
extends Area2D
## The vulnerable part of an actor. Detects Hitboxes and reports hits.
##
## Set the collision mask to the attack layer that should hurt this actor
## (for example `player_attacks` for enemies). If `health` is set, damage is
## applied automatically; the owner listens to `hurt` for everything else
## (knockback, flashing, sounds).

signal hurt(hitbox: Hitbox)

@export var health: Health
## Seconds of immunity after a hit. 0 means every new hit counts.
@export var invincibility_time := 0.0

var _invincible_left := 0.0


func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_invincible_left = maxf(_invincible_left - delta, 0.0)


func is_invincible() -> bool:
	return _invincible_left > 0.0


func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox == null or is_invincible():
		return
	if health and health.is_dead():
		return

	_invincible_left = invincibility_time
	hurt.emit(hitbox)
	if health:
		health.take_damage(hitbox.damage)
