extends Node
## Reuses short-lived scenes instead of freeing them (autoload "Pool").
##
## Projectiles and blasts are spawned and gone within a second, many times
## a fight. `take()` hands out a parked instance of the scene, or makes one
## when none is free; `release()` takes a node out of the tree and parks
## it for the next `take()`. Nothing is freed until the game quits.
##
## A pooled node's `_ready()` runs only once, so a script that changes its
## own state while alive defines `_on_pool_reuse()` to put it back. It is
## called on every `take()` of a node that was used before, before the
## caller sets it up and adds it to the tree.

const _SCENE_META := &"pool_scene"
const _FREE_META := &"pool_free"

## PackedScene -> Array[Node] of parked instances, out of the tree.
var _free := {}


## A ready-to-use instance of `scene`, not in the tree yet: set it up and
## add it like a fresh `instantiate()`.
func take(scene: PackedScene) -> Node:
	var parked: Array = _free.get(scene, [])
	while not parked.is_empty():
		var node: Node = parked.pop_back()
		if is_instance_valid(node):
			node.set_meta(_FREE_META, false)
			# A prewarmed node that never entered the tree is still fresh.
			if node.is_node_ready() and node.has_method(&"_on_pool_reuse"):
				node.call(&"_on_pool_reuse")
			return node
	return _make(scene)


## Takes `node` out of the tree and parks it. Safe to call from physics
## callbacks and more than once. A node not made by `take()` is freed.
func release(node: Node) -> void:
	if not node.has_meta(_SCENE_META):
		node.queue_free()
		return
	if node.get_meta(_FREE_META, false):
		return
	node.set_meta(_FREE_META, true)
	# Deferred: an area can't leave the tree while physics is flushing.
	_park.call_deferred(node)


## True while `node` is out in the game: taken and not released since.
func in_use(node: Node) -> bool:
	return is_instance_valid(node) and not node.get_meta(_FREE_META, false)


## Makes sure at least `count` instances of `scene` are parked, so the
## first shots of a fight don't stall on loading. Call from `_ready()`.
func prewarm(scene: PackedScene, count: int) -> void:
	if scene == null:
		return
	var parked: Array = _free.get_or_add(scene, [])
	while parked.size() < count:
		var node := _make(scene)
		node.set_meta(_FREE_META, true)
		parked.append(node)


func _make(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	node.set_meta(_SCENE_META, scene)
	node.set_meta(_FREE_META, false)
	return node


func _park(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent:
		parent.remove_child(node)
	(_free.get_or_add(node.get_meta(_SCENE_META), []) as Array).append(node)


func _exit_tree() -> void:
	for parked: Array in _free.values():
		for node: Node in parked:
			if is_instance_valid(node):
				node.free()
	_free.clear()
