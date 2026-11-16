class_name PlayerItemEffects
extends Node
## Runs the effects of the items the player carries and wears.
##
## Lasting effects (`ItemEffect.Trigger.OWNED`, `EQUIPPED`) are worked
## out again whenever the inventory or health changes: the ones that
## should run and don't are started, the ones that run and shouldn't are
## stopped. Event effects (ON_HIT, ON_KILL, ON_HURT) of worn items start
## when the event happens and, with a duration, stop once it runs out.
## A new event restarts that clock instead of stacking.
##
## Every effect runs under its own source (`item:<id>:<index>`), so stat
## modifiers come off cleanly.

## source -> [Item, ItemEffect] for the lasting effects that run.
var _lasting: Dictionary[StringName, Array] = {}
## source -> seconds left, for event effects with a duration.
var _timed: Dictionary[StringName, float] = {}
## Starting or stopping an effect can change health, which asks for
## another refresh. That one runs after the current pass instead of inside.
var _refreshing := false
var _dirty := false

@onready var player := owner as Player
@onready var inventory: PlayerInventory = get_parent().get_node(^"Inventory")


func _ready() -> void:
	await owner.ready
	inventory.changed.connect(_refresh)
	player.health.health_changed.connect(func(_c: int, _m: int) -> void: _refresh())
	player.hurtbox.hurt.connect(func(_hitbox: Hitbox) -> void: _fire(ItemEffect.Trigger.ON_HURT))
	Events.enemy_killed.connect(func() -> void: _fire(ItemEffect.Trigger.ON_KILL))
	for hitbox in player.find_children("*", "Hitbox"):
		(hitbox as Hitbox).hit_landed.connect(_on_hit_landed)
	_refresh()


func _physics_process(delta: float) -> void:
	for source: StringName in _timed.keys():
		_timed[source] -= delta
		if _timed[source] <= 0.0:
			_timed.erase(source)
			_effect_of(source).stop(player, source)


## Starts and stops lasting effects so exactly the right ones run.
func _refresh() -> void:
	if _refreshing:
		_dirty = true
		return
	_refreshing = true
	_dirty = true
	while _dirty:
		_dirty = false
		_refresh_once()
	_refreshing = false


func _refresh_once() -> void:
	var wanted: Dictionary[StringName, Array] = {}
	for item in inventory.all:
		for i in item.effects.size():
			var effect := item.effects[i]
			if effect.is_lasting() and _should_run(item, effect):
				wanted[_source(item, i)] = [item, effect]
	for source: StringName in _lasting.keys():
		if not wanted.has(source):
			var effect := _lasting[source][1] as ItemEffect
			_lasting.erase(source)
			effect.stop(player, source)
	for source: StringName in wanted:
		if not _lasting.has(source):
			_lasting[source] = wanted[source]
			(wanted[source][1] as ItemEffect).start(player, source)


func _should_run(item: Item, effect: ItemEffect) -> bool:
	if not inventory.owns(item):
		return false
	if effect.trigger == ItemEffect.Trigger.EQUIPPED and not inventory.is_worn(item):
		return false
	return _health_ok(effect)


func _health_ok(effect: ItemEffect) -> bool:
	if effect.below_health >= 1.0:
		return true
	var health := player.health
	return health.current < health.max_health * effect.below_health


## An event happened: sets off the matching effects of worn items.
func _fire(trigger: ItemEffect.Trigger) -> void:
	for item in inventory.all:
		if not inventory.is_worn(item):
			continue
		for i in item.effects.size():
			var effect := item.effects[i]
			if effect.trigger != trigger or not _health_ok(effect) or randf() >= effect.chance:
				continue
			var source := _source(item, i)
			if _timed.has(source):
				_timed[source] = effect.duration
				continue
			effect.start(player, source)
			if effect.duration > 0.0:
				_timed[source] = effect.duration


func _on_hit_landed(hurtbox: Hurtbox) -> void:
	if hurtbox.rewards_attacker:
		_fire(ItemEffect.Trigger.ON_HIT)


func _source(item: Item, index: int) -> StringName:
	return StringName("item:%s:%d" % [item.id, index])


func _effect_of(source: StringName) -> ItemEffect:
	var parts := String(source).split(":")
	return inventory.find(StringName(parts[1])).effects[int(parts[2])]
