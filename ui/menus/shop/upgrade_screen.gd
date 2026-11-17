class_name UpgradeScreen
extends MenuScreen
## A paid upgrade shrine's page: what the upgrade adds, its price and the
## player's currency. "Offer" pays with the wallet, calls `on_paid` (which
## gives the upgrade) and closes the menu. "Leave" is focused first, so a
## stray press of accept spends nothing.

var _kind: PlayerUpgrades.Kind
var _price: int
var _player: Player
var _on_paid: Callable


func _init(kind: PlayerUpgrades.Kind, price: int, player: Player, on_paid: Callable) -> void:
	_kind = kind
	_price = price
	_player = player
	_on_paid = on_paid


func _build() -> void:
	add_title(PlayerUpgrades.kind_name(_kind))
	add_text("Raises it by %d for good and fills it." % roundi(_player.upgrades.step(_kind)))
	add_gap()
	add_text("Price: %d    You have: %d" % [_price, _player.wallet.amount])
	add_gap()
	add_button("Leave", go_back)
	var offer := add_button("Offer", _offer)
	if _player.wallet.amount < _price:
		offer.text = "Not enough currency"
		offer.disabled = true


func _offer() -> void:
	if not _player.wallet.spend(_price):
		return
	_on_paid.call()
	menu.close()
