class_name PlayerUpgrades
extends Node
## Permanent upgrades to the player's stats. Each one adds a fixed step to
## a stat as a FLAT modifier, under one source per kind (`upgrades_health`,
## `upgrades_flasks`...). An upgrade replaces only its own kind's modifier:
## taking the others away for a moment would lower their maximums and cut
## the current health, spirit or flasks down with them.
##
## - HEALTH and SPIRIT come from upgrade shrines (`StatUpgrade`) and fill
##   the raised bar.
## - FLASKS comes from empty flasks found in the world (`EmptyFlask`). It
##   adds an empty flask that the next rest fills.
## - FLASK_HEAL comes from a flask healer (`FlaskHealer`): every flask
##   heals more. Nothing is filled.
##
## A global save system (see `SaveManager`): the number of upgrades of each
## kind is written to disk whenever the game saves. Loading applies the
## modifiers again without filling anything.

## Saved as numbers in scenes (`StatUpgrade.kind`), so new kinds go at the end.
enum Kind { HEALTH, SPIRIT, FLASKS, FLASK_HEAL }

const SOURCE_PREFIX := "upgrades_"
## The stat each kind raises.
const STATS := {
	Kind.HEALTH: Stats.MAX_HEALTH,
	Kind.SPIRIT: PlayerStats.MAX_SPIRIT,
	Kind.FLASKS: PlayerStats.FLASK_COUNT,
	Kind.FLASK_HEAL: PlayerStats.FLASK_HEAL,
}
## Save data key per kind.
const KEYS := {
	Kind.HEALTH: "health",
	Kind.SPIRIT: "spirit",
	Kind.FLASKS: "flasks",
	Kind.FLASK_HEAL: "flask_heal",
}

## Max health added by each health upgrade.
@export var health_step := 20.0
## Max spirit added by each spirit upgrade.
@export var spirit_step := 15.0
## Flasks added by each empty flask.
@export var flask_step := 1.0
## Health each flask heals more per flask healing upgrade.
@export var flask_heal_step := 10.0

var save_id := &"upgrades"
var _counts := {Kind.HEALTH: 0, Kind.SPIRIT: 0, Kind.FLASKS: 0, Kind.FLASK_HEAL: 0}

@onready var player := owner as Player


func _ready() -> void:
	SaveManager.register(self)


func count(kind: Kind) -> int:
	return _counts[kind]


## Adds one upgrade of `kind`. Health and spirit upgrades fill that bar.
func upgrade(kind: Kind) -> void:
	_counts[kind] += 1
	_apply(kind)
	match kind:
		Kind.HEALTH:
			player.health.heal(player.health.max_health)
		Kind.SPIRIT:
			player.spirit.add(player.spirit.get_max())
	Events.player_upgraded.emit(kind_name(kind))


## What one upgrade of `kind` adds.
func step(kind: Kind) -> float:
	match kind:
		Kind.HEALTH:
			return health_step
		Kind.SPIRIT:
			return spirit_step
		Kind.FLASKS:
			return flask_step
	return flask_heal_step


## The kind's name, translated. Static, so `TranslationServer.tr()`
## stands in for `tr()`.
static func kind_name(kind: Kind) -> String:
	var names := {
		Kind.HEALTH: TranslationServer.tr("Max health"),
		Kind.SPIRIT: TranslationServer.tr("Max spirit"),
		Kind.FLASKS: TranslationServer.tr("Flasks"),
		Kind.FLASK_HEAL: TranslationServer.tr("Flask healing"),
	}
	return names[kind]


func get_save_data() -> Dictionary:
	var data := {}
	for kind: Kind in KEYS:
		data[KEYS[kind]] = _counts[kind]
	return data


func apply_save_data(data: Dictionary) -> void:
	for kind: Kind in KEYS:
		_counts[kind] = maxi(int(data.get(KEYS[kind], 0)), 0)
		_apply(kind)


## Replaces `kind`'s modifier with one that matches its count. Adds the
## new one before removing the old, so the stat never dips in between.
func _apply(kind: Kind) -> void:
	var source := StringName(SOURCE_PREFIX + KEYS[kind])
	var old := player.stats.modifiers_from(source)
	if _counts[kind] > 0:
		player.stats.add_modifier(
			StatModifier.create(STATS[kind], step(kind) * _counts[kind]), source
		)
	for modifier in old:
		player.stats.remove_modifier(modifier, source)
