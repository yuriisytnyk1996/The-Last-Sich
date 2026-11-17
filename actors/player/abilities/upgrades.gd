class_name PlayerUpgrades
extends Node
## Permanent upgrades to max health and max spirit, given by upgrade
## shrines (`StatUpgrade`). Each one adds a fixed step to the stat as a
## FLAT modifier under the `upgrades` source and fills the raised bar.
##
## A global save system (see `SaveManager`): the number of upgrades of each
## kind is written to disk whenever the game saves. Loading applies the
## modifiers again without filling anything.

enum Kind { HEALTH, SPIRIT }

const SOURCE := &"upgrades"
## The stat each kind raises.
const STATS := {Kind.HEALTH: Stats.MAX_HEALTH, Kind.SPIRIT: PlayerStats.MAX_SPIRIT}

## Max health added by each health upgrade.
@export var health_step := 20.0
## Max spirit added by each spirit upgrade.
@export var spirit_step := 15.0

var save_id := &"upgrades"
var _counts := {Kind.HEALTH: 0, Kind.SPIRIT: 0}

@onready var player := owner as Player


func _ready() -> void:
	SaveManager.register(self)


func count(kind: Kind) -> int:
	return _counts[kind]


## Adds one upgrade of `kind`, then fills that bar.
func upgrade(kind: Kind) -> void:
	_counts[kind] += 1
	_apply()
	if kind == Kind.HEALTH:
		player.health.heal(player.health.max_health)
	else:
		player.spirit.add(player.spirit.get_max())
	Events.player_upgraded.emit(kind_name(kind))


## What one upgrade of `kind` adds.
func step(kind: Kind) -> float:
	return health_step if kind == Kind.HEALTH else spirit_step


static func kind_name(kind: Kind) -> String:
	return "Max health" if kind == Kind.HEALTH else "Max spirit"


func get_save_data() -> Dictionary:
	return {"health": _counts[Kind.HEALTH], "spirit": _counts[Kind.SPIRIT]}


func apply_save_data(data: Dictionary) -> void:
	_counts[Kind.HEALTH] = maxi(int(data.get("health", 0)), 0)
	_counts[Kind.SPIRIT] = maxi(int(data.get("spirit", 0)), 0)
	_apply()


## Replaces the modifiers with ones that match the counts.
func _apply() -> void:
	var stats := player.stats
	stats.remove_source(SOURCE)
	for kind: Kind in STATS:
		if _counts[kind] > 0:
			stats.add_modifier(StatModifier.create(STATS[kind], step(kind) * _counts[kind]), SOURCE)
