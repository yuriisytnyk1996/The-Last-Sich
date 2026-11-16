class_name ShopItem
extends InteractionArea
## A shop stand with one item for sale. Pressing interact pauses the game
## and opens a `BuyScreen` with the item, its price and the player's
## currency. Once bought the stand is empty for good: the room saves that
## through the `persistent` group. A stand whose item the player already
## has (found elsewhere) empties itself when used.

@export var item: Item
## Price on this stand. Below 0 uses the item's own `price`.
@export var price := -1

var _sold := false


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)


func get_price() -> int:
	return item.price if price < 0 else price


func _activate(player: Node2D) -> void:
	var buyer := player as Player
	if _sold:
		return
	if buyer.inventory.owns(item):
		_sell_out()
		return
	buyer.velocity.x = 0.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(BuyScreen.new(item, get_price(), buyer, _sell_out))


func get_save_data() -> Dictionary:
	return {"sold": _sold}


func apply_save_data(data: Dictionary) -> void:
	if data.get("sold", false):
		_sell_out()


## Hides the item and the prompt; the empty stand stays.
func _sell_out() -> void:
	_sold = true
	$Item.hide()
	_show_prompt(false)
	set_deferred(&"monitoring", false)
