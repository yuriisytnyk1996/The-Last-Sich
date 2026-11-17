class_name CleanseScreen
extends MenuScreen
## A cleanse point's page: the number of death marks, the price to clear
## them all and the player's currency. "Cleanse" pays with the wallet,
## calls `DeathPenalty.clear()` and closes the menu. "Leave" is focused
## first, so a stray press of accept spends nothing.

var _penalty: DeathPenalty
var _price: int
var _player: Player


func _init(penalty: DeathPenalty, price: int, player: Player) -> void:
	_penalty = penalty
	_price = price
	_player = player


func _build() -> void:
	add_title("Cleanse")
	add_text("Clears every death mark at once, wherever it was left.")
	add_gap()
	var marks := _penalty.count()
	if marks == 0:
		add_text("You carry no death marks.")
		add_gap()
		add_button("Leave", go_back)
		return
	add_text("Death marks: %d" % marks)
	add_text("Price: %d    You have: %d" % [_price, _player.wallet.amount])
	add_gap()
	add_button("Leave", go_back)
	var cleanse := add_button("Cleanse", _cleanse)
	if _player.wallet.amount < _price:
		cleanse.text = "Not enough currency"
		cleanse.disabled = true


func _cleanse() -> void:
	if not _player.wallet.spend(_price):
		return
	_penalty.clear()
	menu.close()
