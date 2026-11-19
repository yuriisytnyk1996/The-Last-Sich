class_name FlaskHealerScreen
extends MenuScreen
## A flask healer's page: how much more each flask would heal, the two
## things the healer asks for (a vial of living water and currency), each
## shown in red while the player lacks it. "Offer" gives both and the
## upgrade (`FlaskHealer.upgrade()`), then closes. "Leave" is focused
## first, so a stray press of accept spends nothing.

const SHORT := Color(0.85, 0.3, 0.3)

var _healer: FlaskHealer
var _player: Player


func _init(healer: FlaskHealer, player: Player) -> void:
	_healer = healer
	_player = player


func _build() -> void:
	add_title(PlayerUpgrades.kind_name(PlayerUpgrades.Kind.FLASK_HEAL))
	if _healer.is_done(_player):
		add_text(tr("Your flasks are as strong as living water can make them."))
		add_gap()
		add_button(tr("Leave"), go_back)
		return
	var flasks := _player.flasks
	var step := roundi(_player.upgrades.step(PlayerUpgrades.Kind.FLASK_HEAL))
	add_text(tr("Each flask heals %d more (%d now).") % [step, flasks.heal_amount()])
	add_text(tr("Level %d of %d") % [_healer.level(_player) + 1, _healer.prices.size()])
	add_gap()
	var vial := _healer.offering(_player)
	var water := add_text(tr("Living water: %s") % (tr(vial.title) if vial else tr("none")))
	_mark_short(water, vial == null)
	var price := _healer.next_price(_player)
	var cost := add_text(tr("Price: %d    You have: %d") % [price, _player.wallet.amount])
	_mark_short(cost, _player.wallet.amount < price)
	add_gap()
	add_button(tr("Leave"), go_back)
	var offer := add_button(tr("Offer"), _offer)
	if vial == null or _player.wallet.amount < price:
		offer.text = tr("Not enough to offer")
		offer.disabled = true


func _offer() -> void:
	if _healer.upgrade(_player):
		menu.close()


func _mark_short(label: Label, short: bool) -> void:
	if short:
		label.add_theme_color_override(&"font_color", SHORT)
