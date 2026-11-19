class_name SummonEffect
extends ItemEffect
## Summons a scene next to the player for as long as the effect runs: a
## ring of sabres, a warding circle, a ghostly ally, falcons for a duma
## (with a `duration`), or a light that follows the wearer of a relic
## (EQUIPPED, while worn).
##
## The scene's root needs `follow(player)`, called before it is added, and
## `dismiss()`, called when the effect stops. It is added under the
## player's parent (the `World`), so it goes along into other rooms.

@export var scene: PackedScene

## source -> the summoned node while it runs.
var _summoned: Dictionary[StringName, Node] = {}


func start(player: Player, source: StringName) -> void:
	if scene == null:
		return
	stop(player, source)
	var node := scene.instantiate()
	node.follow(player)
	_add(player.get_parent(), node)
	_summoned[source] = node


func stop(_player: Player, source: StringName) -> void:
	# Untyped: a room change may already have freed it, and a freed
	# node can't be stored in a typed variable.
	var node: Variant = _summoned.get(source)
	_summoned.erase(source)
	if is_instance_valid(node):
		node.dismiss()


## A worn relic starts its effect while the game loads, before the
## `World` is ready to take children: then it is added once it is.
func _add(parent: Node, node: Node) -> void:
	if parent.is_node_ready():
		parent.add_child(node)
		return
	var add_later := func() -> void:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			parent.add_child(node)
	parent.ready.connect(add_later, CONNECT_ONE_SHOT)
