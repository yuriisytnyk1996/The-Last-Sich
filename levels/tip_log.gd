class_name TipLog
extends Node
## Shows each "how to play" card (`Tip`) once, the first time it comes up,
## and remembers which ones the player has seen (global save system
## "tips", per slot). The pause menu lists the seen ones for rereading.
##
## A tip is asked for with `Events.tip_requested` (an `Execution` when a
## finisher first appears, a `TipArea` in a room) or by the events this
## node watches itself: the first two deaths, the first charm, blade and
## relic obtained, and the first duma worn. A card pauses the game.
## Requests made while the game is paused (a shop, a room transition,
## another card) wait in a queue until it runs again. With tips off in
## the options nothing is shown or marked seen. A child of the `World`.

## Every tip, in the order the pause menu lists them.
@export var all: Array[Tip] = []
## Watched for the first duma worn.
@export var inventory: PlayerInventory
@export var first_death_tip: Tip
@export var second_death_tip: Tip
@export var charm_tip: Tip
@export var blade_tip: Tip
@export var relic_tip: Tip
@export var duma_tip: Tip

var save_id := &"tips"
## Last gameplay input came from a gamepad: cards name its buttons.
var gamepad := false
var _seen: Array[StringName] = []
var _queue: Array[Tip] = []


func _ready() -> void:
	SaveManager.register(self)
	Events.tip_requested.connect(request)
	Events.player_died.connect(_on_player_died)
	Events.item_obtained.connect(_on_item_obtained)
	if inventory:
		inventory.changed.connect(_on_inventory_changed)


## Queues `tip` unless tips are off or it was already seen or queued.
func request(tip: Tip) -> void:
	if tip == null or not AccessibilitySettings.tips or has_seen(tip) or tip in _queue:
		return
	_queue.append(tip)


func has_seen(tip: Tip) -> bool:
	return tip.id in _seen


## The tips listed in the pause menu: seen or known from the start, in
## `all` order.
func seen_tips() -> Array[Tip]:
	return all.filter(func(tip: Tip) -> bool: return tip.known_from_start or has_seen(tip))


## Only runs while the game isn't paused.
func _process(_delta: float) -> void:
	if _queue.is_empty():
		return
	var tip: Tip = _queue.pop_front()
	_seen.append(tip.id)
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(TipScreen.new([tip], 0, gamepad, false))


func _input(event: InputEvent) -> void:
	var device := Tip.device_of(event)
	if device >= 0:
		gamepad = device == 1


func _on_player_died() -> void:
	if first_death_tip and not has_seen(first_death_tip):
		request(first_death_tip)
	else:
		request(second_death_tip)


func _on_item_obtained(item: Item) -> void:
	match item.kind:
		Item.Kind.CHARM:
			request(charm_tip)
		Item.Kind.BLADE:
			request(blade_tip)
		Item.Kind.RELIC:
			request(relic_tip)


## Shown once a duma is worn, not when found: it explains singing it.
func _on_inventory_changed() -> void:
	if not inventory.worn_of(Item.Kind.DUMA).is_empty():
		request(duma_tip)


func get_save_data() -> Dictionary:
	return {"seen": _seen.duplicate()}


## Also drops the queue: systems loaded before this one (a worn duma)
## may have asked for tips that turn out to be seen.
func apply_save_data(data: Dictionary) -> void:
	_seen.clear()
	_queue.clear()
	var saved: Variant = data.get("seen", [])
	if saved is Array:
		for id: Variant in saved:
			_seen.append(StringName(str(id)))
