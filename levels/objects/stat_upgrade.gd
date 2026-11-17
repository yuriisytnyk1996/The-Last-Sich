class_name StatUpgrade
extends InteractionArea
## An upgrade shrine: press interact for one permanent upgrade to max
## health or max spirit (`PlayerUpgrades.upgrade()`), which also fills
## that bar. Free shrines give it at once. A shrine with a `price` pauses
## the game and opens an `UpgradeScreen` to pay currency first.
##
## Used once: the room saves that through the `persistent` group, so the
## shrine stays spent.

const GEM_COLORS := {
	PlayerUpgrades.Kind.HEALTH: Color(0.85, 0.2, 0.25),
	PlayerUpgrades.Kind.SPIRIT: Color(0.45, 0.6, 1),
}

@export var kind := PlayerUpgrades.Kind.HEALTH
## Currency to pay. 0 is free.
@export var price := 0

var _spent := false


func _ready() -> void:
	super()
	add_to_group(SaveManager.PERSISTENT_GROUP)
	$Visual/Gem.color = GEM_COLORS[kind]


func is_spent() -> bool:
	return _spent


func _activate(player: Node2D) -> void:
	if _spent:
		return
	var taker := player as Player
	if price <= 0:
		_give(taker)
		return
	taker.velocity.x = 0.0
	var menu := PausingMenu.new()
	menu.free_on_close = true
	add_child(menu)
	menu.open_screen(UpgradeScreen.new(kind, price, taker, _give.bind(taker)))


func get_save_data() -> Dictionary:
	return {"spent": _spent}


func apply_save_data(data: Dictionary) -> void:
	if data.get("spent", false):
		_spend()


func _give(player: Player) -> void:
	player.upgrades.upgrade(kind)
	_spend()


## Hides the gem and the prompt; the empty shrine stays.
func _spend() -> void:
	_spent = true
	$Visual/Gem.hide()
	_show_prompt(false)
	set_deferred(&"monitoring", false)
