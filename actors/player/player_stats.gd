class_name PlayerStats
extends Stats
## The player's stats: the base values below, plus whatever items, skills
## and effects add as modifiers. Health, Flasks, Spirit, Parry, the dash
## and every player hitbox read from here.

const FLASK_COUNT := &"flask_count"
const FLASK_HEAL := &"flask_heal"
const MAX_SPIRIT := &"max_spirit"
const SPIRIT_PER_HIT := &"spirit_per_hit"
const PARRY_WINDOW := &"parry_window"
const RIPOSTE_WINDOW := &"riposte_window"
const DASH_COOLDOWN := &"dash_cooldown"
const CHARM_SLOTS := &"charm_slots"

@export_group("Health")
@export var max_health := 100.0
## Flasks carried when all are full.
@export var flask_count := 2.0
## Health restored by one flask.
@export var flask_heal := 40.0

@export_group("Offense")
## Multiplier for the damage of every player hitbox and projectile.
@export var damage := 1.0

@export_group("Defense")
## Fraction of damage ignored, per hit element (0 to 1).
@export_range(0.0, 1.0) var normal_resist := 0.0
@export_range(0.0, 1.0) var contact_resist := 0.0
@export_range(0.0, 1.0) var fire_resist := 0.0
@export_range(0.0, 1.0) var poison_resist := 0.0

@export_group("Spirit")
## Maximum spirit without death marks.
@export var max_spirit := 30.0
## Spirit gained per landed hit.
@export var spirit_per_hit := 2.0

@export_group("Timing")
## Seconds the parry guard is up after the press (s).
@export var parry_window := 0.25
## After a parry, seconds to press attack for a riposte (s).
@export var riposte_window := 0.5
## Seconds before the next dash (s).
@export var dash_cooldown := 0.4

@export_group("Items")
## Charms the player can wear at once. Pouches add more.
@export var charm_slots := 3.0


func _define_stats() -> void:
	define(MAX_HEALTH, max_health, 1.0, 500.0)
	define(FLASK_COUNT, flask_count, 0.0, 10.0)
	define(FLASK_HEAL, flask_heal, 0.0)
	define(DAMAGE, damage, 0.0)
	define(NORMAL_RESIST, normal_resist, 0.0, 1.0)
	define(CONTACT_RESIST, contact_resist, 0.0, 1.0)
	define(FIRE_RESIST, fire_resist, 0.0, 1.0)
	define(POISON_RESIST, poison_resist, 0.0, 1.0)
	define(MAX_SPIRIT, max_spirit, 0.0)
	define(SPIRIT_PER_HIT, spirit_per_hit, 0.0)
	define(PARRY_WINDOW, parry_window, 0.05)
	define(RIPOSTE_WINDOW, riposte_window, 0.05)
	define(DASH_COOLDOWN, dash_cooldown, 0.0)
	define(CHARM_SLOTS, charm_slots, 0.0, 8.0)
