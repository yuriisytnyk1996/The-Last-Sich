# Shops

Shops sell [items](/systems/inventory) for [currency](/systems/currency). A shop is a row of stands, each holding one item. Pressing interact at a stand shows the item, its price and the player's currency, with a choice to buy. A bought item leaves its stand empty for good.

## How it works

1. A `ShopItem` (`levels/objects/items/shop_item.tscn`) is a stand with one `item` and a `price`. A `price` below 0 uses the item's own `Item.price`.
2. Pressing interact at it pauses the game and opens a `PausingMenu` with a `BuyScreen` (`ui/menus/shop/buy_screen.gd`), the same way the skill shrine opens its menu.
3. The screen shows the item's title, kind and description, then "Price: N    You have: M". **Leave** is focused first, so a stray press buys nothing. **Buy** is disabled and reads "Not enough currency" when the wallet holds less than the price.
4. **Buy** calls `PlayerWallet.spend()`, then `PlayerInventory.add()` (the HUD names the item), tells the stand it is sold and closes the menu.
5. A sold stand hides its item and prompt and stops reacting. It saves `sold` through the `persistent` group, so it stays empty.
6. A stand whose item the player already has (found in a room, or from the debug button) empties itself when used, without charging.
7. The [map](/systems/map) marks every cell with a stand with a gold square (once per cell).

### Test shop

The test house sells five items: iron cross, hunter's tally and red sash (charms), heavy edge (blade) and spare gourd (keepsake), at their own prices (see [Inventory](/systems/inventory#items)).

## Files

| File | Role |
|---|---|
| `levels/objects/items/shop_item.gd` / `.tscn` | `ShopItem`: a stand with one item and a price, sold once, saved |
| `ui/menus/shop/buy_screen.gd` | `BuyScreen`: item, price, currency, buy or leave |
| `actors/player/abilities/wallet.gd` | `PlayerWallet.spend()` pays |
| `actors/player/abilities/inventory.gd` | `PlayerInventory.add()` gives the item |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `ShopItem.price` | -1 | Price on this stand. Below 0 uses `Item.price` |
| `Item.price` | 100 | The item's usual price, see the item table on [Inventory](/systems/inventory#items) |

## Extending

- **A new shop:** place `shop_item.tscn` stands in a room's Logic scene, each with an `item`. Set `price` for a stand that sells cheaper or dearer than usual.
- **Selling something that isn't an item** (a flask refill, a map): make a stand that opens its own screen with the same layout as `BuyScreen` and calls `wallet.spend()`.

## Known limitations

- A stand sells one item once. There is no restocking and no shopkeeper.
- Stands are brown boxes with a gold diamond for the item. No purchase sound or animation.
