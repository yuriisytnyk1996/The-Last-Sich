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
enum Kind { CHARM, BLADE, KEEPSAKE }

## Saved to disk. Never rename one that has shipped.
@export var id := &""
@export var title := ""
@export_multiline var description := ""
@export var kind := Kind.CHARM
## What a shop stand asks for it unless the stand sets its own price.
@export var price := 100
@export var effects: Array[ItemEffect] = []


func is_equipable() -> bool:
	return kind != Kind.KEEPSAKE


static func kind_name(of: Kind) -> String:
	return ["Charm", "Blade", "Keepsake"][of]
