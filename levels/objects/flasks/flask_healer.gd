class_name FlaskHealer
extends InteractionArea
## A healer's table: press interact to strengthen every flask
## (`PlayerUpgrades.upgrade(FLASK_HEAL)`). The game pauses on a
## `FlaskHealerScreen`. Each upgrade takes one quest item from `accepted`
## (a vial of living water) and the price for the next level from
## `prices`. Once every price is paid, the healer has nothing more to give.
##
## Stands in for a healer character until there are NPCs. Nothing to save:
## the level is the player's upgrade count.

## Quest items the healer takes, one per upgrade. The first one owned goes.
@export var accepted: Array[Item] = []
## Currency for each level, in order. Its size is the number of levels.
@export var prices: Array[int] = [400, 800, 1200, 1600, 2000]


## Upgrades the player already has here.
func level(player: Player) -> int:
	return player.upgrades.count(PlayerUpgrades.Kind.FLASK_HEAL)


func is_done(player: Player) -> bool:
	return level(player) >= prices.size()


func next_price(player: Player) -> int:
	return 0 if is_done(player) else prices[level(player)]


## The first accepted quest item the player carries, or null.
func offering(player: Player) -> Item:
	for item in accepted:
		if player.inventory.owns(item):
			return item
	return null


## Takes the vial and the price, then gives the upgrade. False when the
## player is short of either.
func upgrade(player: Player) -> bool:
	var vial := offering(player)
	var price := next_price(player)
	if is_done(player) or vial == null or player.wallet.amount < price:
		return false
	player.wallet.spend(price)
	player.inventory.remove(vial)
	player.upgrades.upgrade(PlayerUpgrades.Kind.FLASK_HEAL)
	return true


func _activate(player: Node2D) -> void:
	var taker := player as Player
	taker.velocity.x = 0.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(FlaskHealerScreen.new(self, taker))
