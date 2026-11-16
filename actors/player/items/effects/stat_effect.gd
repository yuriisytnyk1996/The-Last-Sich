class_name StatEffect
extends ItemEffect
## Adds stat modifiers to the player while the effect runs: worn charms,
## or a short boost after a kill.

@export var modifiers: Array[StatModifier] = []


func start(player: Player, source: StringName) -> void:
	for modifier in modifiers:
		player.stats.add_modifier(modifier, source)


func stop(player: Player, source: StringName) -> void:
	player.stats.remove_source(source)
