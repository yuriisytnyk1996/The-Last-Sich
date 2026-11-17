# Inventory

Items the player carries: charms worn in slots for passive bonuses, a [duma](/systems/dumas) sung for spirit, a blade that trades one strength for another, relics (traversal tools such as the seer's lantern) that work while worn, and keepsakes that work just by being carried. What an item does is a list of effects, each with a trigger (carried, worn, on a hit, on a kill, on being hurt, on use). Most effects add [stat](/systems/stats) modifiers. Items are found in rooms or bought at [shops](/systems/shops), listed on the inventory page, and saved.

## How it works

1. Every item is an `Item` resource (`actors/player/items/<kind>s/<id>.tres`) with an `id`, a title, description and optional `icon` for the menus, a `kind`, a shop `price` and a list of `effects`.
2. The player's `Inventory` node (`PlayerInventory`, `actors/player/abilities/inventory.gd`) lists every item in `all`, remembers which ones are owned and which are worn, and enforces the slots. Every change emits `changed`.
3. `PlayerInventory.add(item)` gives the player an item and emits `Events.item_obtained(item)`. The HUD's `ItemToast` names it for a moment ("Found: Wolf fang").
4. The player's `ItemEffects` node (`PlayerItemEffects`, `actors/player/abilities/item_effects.gd`) runs the effects:
   - **Lasting effects** (`OWNED`, `EQUIPPED`) are worked out again whenever the inventory or health changes. Effects that should run and don't are started; effects that run and shouldn't are stopped.
   - **Event effects** (`ON_HIT`, `ON_KILL`, `ON_HURT`) of worn items start when the event happens. With a `duration` they stop again once it runs out; a new event restarts the clock instead of stacking.
   - **Use effects** (`ON_USE`) start when `use(item)` is called: a [duma](/systems/dumas) being sung. Effects with a `duration` run for it plus the extra time passed in (the `duma_duration` stat), then stop. `end_use(item)` stops them early.
   - Each effect runs under its own source, `item:<id>:<index>`, so its stat modifiers come off with `Stats.remove_source()`.
5. `ItemPickup` (`levels/objects/items/item_pickup.tscn`) is an item lying in a room. Interact takes it, once; its room remembers that through the `persistent` group.
6. The **inventory page** (`InventoryScreen`) shows the items, see below.

### Inventory page

Opened with `inventory` (I) or from the pause menu's **Inventory** button. The same key closes it; back closes it or returns to the pause menu.

```
              Charms
   < Q  Charms  Dumas  Blades  Relics  Keepsakes  E >
 Worn                              ┌─────────────────┐
 [■][■][ ][ ][ ][x][x][x]          │       ◆         │
 Carried                           │   Iron cross    │
 [■][■][■][■][■][■][■][■]          │  Charm · Worn   │
 [■][ ][ ][ ][ ][ ][ ][ ]          │  description…   │
 [ ][ ][ ][ ][ ][ ][ ][ ]          └─────────────────┘
 Currency 1234   Accept: Take off    Lore: Read    Back: Close
```

- **Tabs** (`InventoryTabs`): one per kind. `menu_tab_prev` and `menu_tab_next` (Q / E, shoulder buttons) step through them and wrap; tabs can be clicked. The open tab is lit and underlined, and its name is the page title.
- **Worn row**: every slot the kind can ever have (`PlayerInventory.max_slots()`: 8 charms, 1 duma, 1 blade, 3 relics). Open slots show the worn items in order; slots not opened yet are dark and crossed. The row can't be focused; it lights the slot of the item focused in the grid. Keepsakes have no worn row.
- **Grid** (`InventoryGrid`): the owned items of the kind in `all` order, 8 per row, padded with empty cells to at least 3 rows. Worn items have a gold back and frame. The focused cell has a bright frame with corner ticks.
- **Details** (`ItemDetails`): the focused item drawn large, its name, kind (with the spirit cost for a duma) and "Worn", and its description. Empty for an empty cell.
- **Footer**: the currency, then hints for the focused item: "Accept: Wear", "Accept: Take off" or "No free slot", "Lore: Read" when it has lore, and "Back: Close".
- **Accept** on a charm or relic wears it in the first free slot or takes it off; on a blade or duma it replaces the worn one. Keepsakes do nothing. With every slot full the hint reads "No free slot".
- **Lore**: `menu_lore` (R / Y) opens a `LoreScreen` for the focused item: its icon drawn large, its name and its `lore` text. `menu_lore` again or back returns to the inventory, on the same cell. Items without `lore` don't open it. Every item has lore.
- The worn slot is never chosen: wearing always fills the first free slot. The cursor stays in the grid.
- The page opens on the tab and cell of the **newest item** (`PlayerInventory.take_newest()`) when one was added since the last look, else on the tab and cell used last.

Until items have art, `ItemIcon` draws a placeholder: a gold gem for charms, a steel blade for blades, a pale lantern for relics, a leather pouch for keepsakes, a blue scroll for dumas, with the first letter of the title in the corner of small icons. An item with an `icon` texture shows that instead.

### Kinds and slots

| Kind | Slots | Notes |
|---|---|---|
| `CHARM` | `PlayerStats.CHARM_SLOTS` (3, up to 8) | A charm needs a free slot. Pouches raise the stat |
| `DUMA` | 1 (`PlayerInventory.DUMA_SLOTS`) | Wearing a duma replaces the one worn. Sung with the `duma` button, see [Dumas](/systems/dumas) |
| `BLADE` | 1 (`PlayerInventory.BLADE_SLOTS`) | Wearing a blade replaces the one worn |
| `RELIC` | 3 (`PlayerInventory.RELIC_SLOTS`) | Traversal tools. Their `EQUIPPED` effects run only while worn, so the player chooses which to use |
| `KEEPSAKE` | none | Never worn. Its `OWNED` effects run while it is carried |

If the charm slot count drops (a save without the pouch), the last charms worn come off.

### Effects

`ItemEffect` (`actors/player/items/effects/item_effect.gd`) is the base. Every effect has:

| Field | Default | Meaning |
|---|---|---|
| `trigger` | `EQUIPPED` | `OWNED`: while carried. `EQUIPPED`: while worn. `ON_HIT`: a worn item, when a player hitbox lands a hit that rewards the attacker. `ON_KILL`: a worn item, when an enemy dies (`Events.enemy_killed`). `ON_HURT`: a worn item, when the player's hurtbox takes a hit. `ON_USE`: when the item is used, a duma being sung |
| `below_health` | 1.0 | Only while health is below this fraction of the maximum. 1 is always |
| `chance` | 1.0 | Event triggers: chance that the event sets it off |
| `duration` | 0 | Event and use triggers: seconds until it stops. 0 never stops (one-shot effects) |

Three general effects exist (dumas add four of their own, see [Dumas](/systems/dumas#duma-effects)):

- **`StatEffect`**: adds its `modifiers` (`StatModifier` resources) while it runs, removes them on stop.
- **`RestoreEffect`**: gives `amount` health, spirit or currency once when it starts. Health isn't given to a dead player.
- **`UnlockEffect`**: grants a traversal unlock while it runs, see [Traversal](/systems/traversal#unlocks).

### Items

| Item | Kind | Price | Effect |
|---|---|---|---|
| Iron cross | Charm | 300 | Max health +15 |
| Wolf fang | Charm | 400 | Damage +10% |
| Clay amulet | Charm | 250 | Fire resist +0.5 |
| Bitter root | Charm | 250 | Poison resist +0.5 |
| Healer's knot | Charm | 350 | Flask heal +15 |
| Red sash | Charm | 450 | Damage +25% while health is below 30% |
| Brass bell | Charm | 300 | Spirit per hit +1 |
| Hunter's tally | Charm | 400 | Heal 5 on each kill |
| War drum | Charm | 450 | Damage +20% for 5 s after a kill |
| Hare foot | Charm | 350 | Run speed +15% |
| Quick bracer | Charm | 450 | Attack speed +20% |
| Raven eye | Charm | 500 | Critical hit chance +0.15 |
| Heavy edge | Blade | 600 | Damage +30%, dash cooldown +0.3 s |
| Thirsting edge | Blade | 600 | 30% chance to heal 3 on a hit, damage -10% |
| Guarding edge | Blade | 500 | Parry window +0.1 s, riposte window +0.25 s, max health -10 |
| Leather pouch | Keepsake | 500 | Charm slots +1 |
| Stitched pouch | Keepsake | 900 | Charm slots +1 |
| Spare gourd | Keepsake | 800 | Flasks +1 |
| Chumak's whip | Keepsake | 600 | [Travel](/systems/travel) between rest points |
| Icon lamp | Keepsake | 500 | Rest points fill [spirit](/systems/spirit); respawn with it full |
| Seer's lantern | Relic | 1000 | Shows reveal platforms while worn |

The seven dumas are listed on the [Dumas](/systems/dumas#dumas) page.

The test room holds the hare foot, quick bracer and raven eye, past the training dummy. The test works room holds the wolf fang (near the start) and the leather pouch (behind the cracked wall). The iron cross, hunter's tally, red sash, heavy edge, spare gourd, Chumak's whip and icon lamp are sold at the test house [shop](/systems/shops). The seer's lantern is in a chest in the [test vault](/systems/traversal#test-vault-layout). The dumas are in the test room, past the pit. The rest are only reachable through the debug button for now.

### Saving

`PlayerInventory` is a global save system (`inventory`, see [Save system](/systems/save-system)): the owned and worn ids are saved when the player rests or dies. Ids the game no longer knows are dropped on load, so removing an item can't break a save.

### Debug

In debug builds the inventory page footer has a **Debug: get all** button (mouse only) (`PlayerInventory.add_all()`). It adds every item without the HUD toast; they are saved like normal items the next time the game saves.

## Files

| File | Role |
|---|---|
| `actors/player/items/item.gd` | `Item` resource: id, title, description, lore, kind, price, effects, a duma's spirit cost |
| `actors/player/items/effects/item_effect.gd` | `ItemEffect` base: trigger, health condition, chance, duration |
| `actors/player/items/effects/stat_effect.gd` | `StatEffect`: stat modifiers while it runs |
| `actors/player/items/effects/restore_effect.gd` | `RestoreEffect`: health, spirit or currency once |
| `actors/player/items/effects/unlock_effect.gd` | `UnlockEffect`: a traversal unlock while it runs |
| `actors/player/items/charms/`, `dumas/`, `blades/`, `relics/`, `keepsakes/` | One `.tres` per item |
| `actors/player/abilities/inventory.gd` | `PlayerInventory`: every item, owned, worn, slots, saved |
| `actors/player/abilities/item_effects.gd` | `PlayerItemEffects`: starts and stops effects |
| `levels/objects/items/item_pickup.gd` / `.tscn` | `ItemPickup`: an item to pick up once |
| `ui/menus/inventory/inventory_screen.gd` | `InventoryScreen`: the inventory page, tab keys, wear and take off |
| `ui/menus/inventory/inventory_tabs.gd` | `InventoryTabs`: the tab bar |
| `ui/menus/inventory/inventory_grid.gd` | `InventoryGrid`: worn row and item grid for one kind |
| `ui/menus/inventory/item_cell.gd` | `ItemCell`: one square, with its frame per state |
| `ui/menus/inventory/item_details.gd` | `ItemDetails`: the focused item's panel |
| `ui/menus/inventory/lore_screen.gd` | `LoreScreen`: one item's lore page |
| `ui/menus/inventory/item_icon.gd` | `ItemIcon`: the item's icon, or a placeholder shape |
| `ui/hud/item_toast.gd` | `ItemToast`: names a new item in the HUD |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `PlayerStats.charm_slots` | 3 | Charm slots at the start (stat range 0 to 8) |
| `PlayerInventory.BLADE_SLOTS` | 1 | Blades worn at once (constant) |
| `PlayerInventory.RELIC_SLOTS` | 3 | Relics worn at once (constant) |
| `PlayerInventory.DUMA_SLOTS` | 1 | Dumas worn at once (constant) |
| `PlayerStats.MAX_CHARM_SLOTS` | 8 | Most charm slots there can be; the worn row shows this many (constant) |
| `InventoryGrid.COLUMNS` / `MIN_ROWS` | 8 / 3 | Grid size (constants) |
| `ItemToast.show_time` | 2.0 | Seconds the item name stays fully visible |
| `ItemToast.fade_time` | 0.5 | Seconds it takes to fade out |
| `Item.price` / effect values | per item | See the item table |

## Extending

- **A new item:** create an `Item` `.tres` in the folder of its kind, give it a unique `id`, a `description` (what it does) and a `lore` (its story, no numbers), add effects, and add it to `Inventory.all` on the player scene (the inventory page lists items in that order). Never rename an `id` that has been saved.
- **A new effect type:** extend `ItemEffect` and override `start()` and `stop()`. `start()` gets the player and the effect's source.
- **A new trigger:** add it to `ItemEffect.Trigger`, connect the event in `PlayerItemEffects._ready()` and call `_fire()` with it.
- **Selling an item:** place a `ShopItem` stand, see [Shops](/systems/shops).
- **Giving an item from a script** (a boss reward, a chest): `player.inventory.add(item)`.
- **Checking for an item** (a key for a door): `player.inventory.owns(item)`.

## Known limitations

- Hits from projectiles and blasts spawned after the player is ready don't set off `ON_HIT` effects, the same as for spirit.
- Event effects that are running when their item is taken off keep going until their duration runs out.
- Placeholder shapes instead of item icons, no menu sounds or cursor animation. Pickups are gold diamonds with no pickup animation.
- The grid grows instead of scrolling, which is fine for a few dozen items per kind.
- The worn row is display only: a charm is taken off by choosing it in the grid.
