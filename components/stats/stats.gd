class_name Stats
extends Node
## Named numbers (max health, damage, parry window...) that items, skills
## and effects can change without touching the code that reads them.
##
## Each stat has a base value and a range. Modifiers are added under a
## source (an item id, a skill id) and removed by that source, so nothing
## has to remember what it added. The value is
## `(base + flat) × (1 + percent)`, clamped to the stat's range.
## Subclasses declare their stats in `_define_stats()`. Readers call
## `get_value()` each time they need it, or listen to `stat_changed`.

signal stat_changed(stat: StringName)

## Stats shared by every actor that has a `Stats` node.
const MAX_HEALTH := &"max_health"
## Multiplier for the damage of this actor's hitboxes.
const DAMAGE := &"damage"
## Fraction of incoming damage ignored, per hit element (0 to 1).
const NORMAL_RESIST := &"normal_resist"
const CONTACT_RESIST := &"contact_resist"
const FIRE_RESIST := &"fire_resist"
const POISON_RESIST := &"poison_resist"

var _base: Dictionary[StringName, float] = {}
var _range: Dictionary[StringName, Vector2] = {}
## stat -> Array of { "source": StringName, "modifier": StatModifier }
var _modifiers: Dictionary[StringName, Array] = {}
var _defined := false


func _ready() -> void:
	# Every hitbox in the owner's scene deals damage with these stats.
	# Projectiles are spawned later and get them from whoever spawns them.
	if owner:
		for hitbox in owner.find_children("*", "Hitbox"):
			(hitbox as Hitbox).attacker_stats = self


## Declares a stat. Called from `_define_stats()`.
func define(stat: StringName, base: float, min_value := 0.0, max_value := INF) -> void:
	_base[stat] = base
	_range[stat] = Vector2(min_value, max_value)
	_modifiers[stat] = []


func has_stat(stat: StringName) -> bool:
	_ensure_defined()
	return _base.has(stat)


## Value with every modifier applied. `fallback` for a stat this node
## doesn't have, so readers can treat a missing stat as neutral.
func get_value(stat: StringName, fallback := 0.0) -> float:
	if not has_stat(stat):
		return fallback
	var flat := 0.0
	var percent := 0.0
	for entry: Dictionary in _modifiers[stat]:
		var modifier: StatModifier = entry.modifier
		if modifier.kind == StatModifier.Kind.FLAT:
			flat += modifier.value
		else:
			percent += modifier.value
	var limits := _range[stat]
	return clampf((_base[stat] + flat) * (1.0 + percent), limits.x, limits.y)


func get_base(stat: StringName) -> float:
	return _base[stat] if has_stat(stat) else 0.0


func add_modifier(modifier: StatModifier, source: StringName) -> void:
	if not has_stat(modifier.stat):
		push_warning("Stats: no stat '%s' on %s" % [modifier.stat, get_path()])
		return
	_modifiers[modifier.stat].append({"source": source, "modifier": modifier})
	stat_changed.emit(modifier.stat)


## Adds the modifier for `seconds` of game time (paused time doesn't count).
func add_timed_modifier(modifier: StatModifier, source: StringName, seconds: float) -> void:
	add_modifier(modifier, source)
	await get_tree().create_timer(seconds, false).timeout
	remove_modifier(modifier, source)


## Removes one modifier that `source` added.
func remove_modifier(modifier: StatModifier, source: StringName) -> void:
	if not has_stat(modifier.stat):
		return
	var list: Array = _modifiers[modifier.stat]
	for i in list.size():
		if list[i].source == source and list[i].modifier == modifier:
			list.remove_at(i)
			stat_changed.emit(modifier.stat)
			return


## Removes everything `source` added, for example when an item is taken off.
func remove_source(source: StringName) -> void:
	_ensure_defined()
	for stat in _modifiers:
		var list: Array = _modifiers[stat]
		var before := list.size()
		_modifiers[stat] = list.filter(
			func(entry: Dictionary) -> bool: return entry.source != source
		)
		if _modifiers[stat].size() != before:
			stat_changed.emit(stat)


## Override to declare stats with `define()`. Runs once, the first time
## any stat is read, so readers never depend on node order.
func _define_stats() -> void:
	pass


func _ensure_defined() -> void:
	if _defined:
		return
	_defined = true
	_define_stats()
