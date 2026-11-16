class_name EnemyStats
extends Stats
## An enemy's stats: health, a damage multiplier for all its attacks, and
## resistances per hit element. Set the values on each enemy's `Stats`
## node. Effects (a buff from another enemy, a weakening item) change them
## with modifiers like the player's.

@export var max_health := 60.0
## Multiplier for the damage of every hitbox and projectile of this enemy.
@export var damage := 1.0

@export_group("Defense")
## Fraction of damage ignored, per hit element (0 to 1).
@export_range(0.0, 1.0) var normal_resist := 0.0
@export_range(0.0, 1.0) var contact_resist := 0.0
@export_range(0.0, 1.0) var fire_resist := 0.0
@export_range(0.0, 1.0) var poison_resist := 0.0


func _define_stats() -> void:
	define(MAX_HEALTH, max_health, 1.0)
	define(DAMAGE, damage, 0.0)
	define(NORMAL_RESIST, normal_resist, 0.0, 1.0)
	define(CONTACT_RESIST, contact_resist, 0.0, 1.0)
	define(FIRE_RESIST, fire_resist, 0.0, 1.0)
	define(POISON_RESIST, poison_resist, 0.0, 1.0)
