class_name SummonEffect
extends ItemEffect
## Summons a scene next to the player for as long as the effect runs: a
## ring of sabres around them. For dumas, with a `duration`.
##
## The scene's root needs `follow(player)`, called before it is added, and
## `dismiss()`, called when the effect stops.

@export var scene: PackedScene

## source -> the summoned node while it runs.
var _summoned: Dictionary[StringName, Node] = {}


func start(player: Player, source: StringName) -> void:
	if scene == null:
		return
	stop(player, source)
	var node := scene.instantiate()
	node.follow(player)
	player.get_parent().add_child(node)
	_summoned[source] = node


func stop(_player: Player, source: StringName) -> void:
	var node: Node = _summoned.get(source)
	_summoned.erase(source)
	if is_instance_valid(node):
		node.dismiss()
