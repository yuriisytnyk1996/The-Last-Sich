class_name StatModifier
extends Resource
## One change to one stat, added to a `Stats` node under a source.
##
## A resource, so items and skills can ship their modifiers as `.tres`
## files. The same resource can be added by several sources at once.

## FLAT adds `value` to the base. PERCENT adds `value` as a fraction of
## base plus flat (0.2 is +20 %). Percents from all sources are summed,
## not multiplied, so two +20 % modifiers make +40 %.
enum Kind { FLAT, PERCENT }

## Name of the stat, one of the constants on `Stats` or a subclass.
@export var stat: StringName
@export var kind := Kind.FLAT
@export var value := 0.0


static func create(stat_name: StringName, amount: float, type := Kind.FLAT) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat_name
	modifier.value = amount
	modifier.kind = type
	return modifier
