class_name Item
extends Resource
## Something the player carries: found in rooms (`ItemPickup`) or bought
## at a shop stand (`ShopItem`). Each item is a `.tres` file in a folder
## per kind, listed on the player's `Inventory` node. See
## `PlayerInventory`.
##
## What an item does is its list of `effects`. Each effect says when it
## runs (owned, equipped, on a hit...), so one item can mix a passive
## bonus with a reaction to kills.

## CHARM: worn in charm slots, as many as `PlayerStats.CHARM_SLOTS`.
## BLADE: one slot, usually a trade-off for the weapon.
## KEEPSAKE: never equipped. Works just by being carried (keys, pouches).
## RELIC: worn in `PlayerInventory.RELIC_SLOTS` slots. Traversal tools
## (a lantern that shows hidden platforms) that work only while worn.
## DUMA: one slot. A song sung for `spirit_cost` with the duma button;
## its `ON_USE` effects run then (see `PlayerDumas`).
## QUEST: never equipped and has no effects. Handed over to someone, who
## takes it (`PlayerInventory.remove()`), like living water at a flask
## healer.
## Saved as numbers in `.tres` files, so new kinds go at the end.
enum Kind { CHARM, BLADE, KEEPSAKE, RELIC, DUMA, QUEST }

## Saved to disk. Never rename one that has shipped.
@export var id := &""
@export var title := ""
@export_multiline var description := ""
## Longer flavour text, read on the inventory's lore page. Empty: no page.
@export_multiline var lore := ""
## Shown in the inventory grid. Without one, a placeholder shape is drawn.
@export var icon: Texture2D
@export var kind := Kind.CHARM
## What a shop stand asks for it unless the stand sets its own price.
@export var price := 100
@export var effects: Array[ItemEffect] = []
## Dumas only: spirit spent to sing it, before `PlayerStats.DUMA_COST`.
@export var spirit_cost := 0.0


func is_equipable() -> bool:
	return kind != Kind.KEEPSAKE and kind != Kind.QUEST


## The kind's name, translated. Static, so `TranslationServer.tr()`
## stands in for `tr()`.
static func kind_name(of: Kind) -> String:
	var names: PackedStringArray = [
		TranslationServer.tr("Charm"),
		TranslationServer.tr("Blade"),
		TranslationServer.tr("Keepsake"),
		TranslationServer.tr("Relic"),
		TranslationServer.tr("Duma"),
		TranslationServer.tr("Quest item"),
	]
	return names[of]


## The kind's name for many, translated (inventory tabs).
static func kind_plural(of: Kind) -> String:
	var names: PackedStringArray = [
		TranslationServer.tr("Charms"),
		TranslationServer.tr("Blades"),
		TranslationServer.tr("Keepsakes"),
		TranslationServer.tr("Relics"),
		TranslationServer.tr("Dumas"),
		TranslationServer.tr("Quest items"),
	]
	return names[of]
