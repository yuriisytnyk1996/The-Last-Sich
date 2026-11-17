class_name PlayerInventory
extends Node
## The items the player carries and the ones they wear.
##
## Every item in the game is listed in `all`. `add()` gives one to the
## player (pickups, shops) and announces it through `Events.item_obtained`.
## Charms and blades are worn in slots: as many charm slots as the
## `PlayerStats.CHARM_SLOTS` stat, one blade slot, `RELIC_SLOTS` relic
## slots. Keepsakes are never worn. What items do is up to
## `PlayerItemEffects`, which listens to `changed`.
##
## A global save system (see `SaveManager`): owned and worn ids are
## written to disk whenever the game saves.

## Something was added, removed, worn or taken off.
signal changed

const BLADE_SLOTS := 1
const RELIC_SLOTS := 3

## Every item, in the order the inventory page lists them.
@export var all: Array[Item] = []

var save_id := &"inventory"
## The last item added and not yet looked at. The inventory page opens
## on it (`take_newest()`).
var newest: Item
var _owned: Array[StringName] = []
var _worn: Array[StringName] = []

@onready var player := owner as Player


func _ready() -> void:
	SaveManager.register(self)
	await owner.ready
	player.stats.stat_changed.connect(_on_stat_changed)


func find(id: StringName) -> Item:
	for item in all:
		if item.id == id:
			return item
	return null


func owns(item: Item) -> bool:
	return item.id in _owned


func is_worn(item: Item) -> bool:
	return item.id in _worn


## Owned items of one kind, in `all` order.
func owned_of(kind: Item.Kind) -> Array[Item]:
	return all.filter(func(item: Item) -> bool: return item.kind == kind and owns(item))


func worn_of(kind: Item.Kind) -> Array[Item]:
	return owned_of(kind).filter(is_worn)


func slot_count(kind: Item.Kind) -> int:
	match kind:
		Item.Kind.CHARM:
			return roundi(player.stats.get_value(PlayerStats.CHARM_SLOTS))
		Item.Kind.BLADE:
			return BLADE_SLOTS
		Item.Kind.RELIC:
			return RELIC_SLOTS
	return 0


## The newest item, once: later calls return null until another is added.
func take_newest() -> Item:
	var item := newest
	newest = null
	return item


## Most slots of a kind there can ever be. The inventory page shows the
## ones not opened yet as locked.
func max_slots(kind: Item.Kind) -> int:
	match kind:
		Item.Kind.CHARM:
			return PlayerStats.MAX_CHARM_SLOTS
		Item.Kind.BLADE:
			return BLADE_SLOTS
		Item.Kind.RELIC:
			return RELIC_SLOTS
	return 0


func has_free_slot(kind: Item.Kind) -> bool:
	return worn_of(kind).size() < slot_count(kind)


## Gives the player `item`. Returns false if they already have it.
func add(item: Item) -> bool:
	if item == null or owns(item):
		return false
	_owned.append(item.id)
	newest = item
	changed.emit()
	Events.item_obtained.emit(item)
	return true


## Wears an owned item. A blade replaces the one worn; a charm or relic
## needs a free slot. Returns false when it can't be worn.
func wear(item: Item) -> bool:
	if not owns(item) or not item.is_equipable() or is_worn(item):
		return false
	if item.kind == Item.Kind.BLADE:
		for blade in worn_of(Item.Kind.BLADE):
			_worn.erase(blade.id)
	elif not has_free_slot(item.kind):
		return false
	_worn.append(item.id)
	changed.emit()
	return true


func take_off(item: Item) -> void:
	if _worn.has(item.id):
		_worn.erase(item.id)
		changed.emit()


## Debug: gives the player every item.
func add_all() -> void:
	for item in all:
		if not owns(item):
			_owned.append(item.id)
	changed.emit()


func get_save_data() -> Dictionary:
	return {"owned": _owned.duplicate(), "worn": _worn.duplicate()}


func apply_save_data(data: Dictionary) -> void:
	_owned = _known_ids(data.get("owned", []))
	_worn = _known_ids(data.get("worn", [])).filter(
		func(id: StringName) -> bool: return id in _owned
	)
	changed.emit()


## Ids that still name an item, so a removed item can't break a save.
func _known_ids(ids: Variant) -> Array[StringName]:
	var known: Array[StringName] = []
	if ids is Array:
		for id: Variant in ids:
			if find(StringName(str(id))) != null:
				known.append(StringName(str(id)))
	return known


## Fewer charm slots (a pouch lost) takes off the last charms worn.
func _on_stat_changed(stat: StringName) -> void:
	if stat != PlayerStats.CHARM_SLOTS:
		return
	var charms := worn_of(Item.Kind.CHARM)
	while charms.size() > slot_count(Item.Kind.CHARM):
		_worn.erase(charms.pop_back().id)
	changed.emit()
