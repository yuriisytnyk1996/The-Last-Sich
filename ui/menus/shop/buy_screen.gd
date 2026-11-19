class_name BuyScreen
extends MenuScreen
## A shop stand's page: the item, what it does, its price and the
## player's currency. "Buy" pays with the wallet, adds the item to the
## inventory, calls `on_bought` and closes the menu. "Leave" is focused
## first, so a stray press of accept buys nothing.

var _item: Item
var _price: int
var _player: Player
var _on_bought: Callable


func _init(item: Item, price: int, player: Player, on_bought: Callable) -> void:
	_item = item
	_price = price
	_player = player
	_on_bought = on_bought


func _build() -> void:
	add_title(tr(_item.title))
	add_text(Item.kind_name(_item.kind))
	add_gap(2)
	add_text(tr(_item.description))
	add_gap()
	add_text(tr("Price: %d    You have: %d") % [_price, _player.wallet.amount])
	add_gap()
	add_button(tr("Leave"), go_back)
	var buy := add_button(tr("Buy"), _buy)
	if _player.wallet.amount < _price:
		buy.text = tr("Not enough currency")
		buy.disabled = true


func _buy() -> void:
	if not _player.wallet.spend(_price):
		return
	_player.inventory.add(_item)
	_on_bought.call()
	menu.close()
