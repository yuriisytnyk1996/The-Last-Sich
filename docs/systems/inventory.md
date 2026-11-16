# Inventory

Items the player carries: charms worn in slots for passive bonuses, a blade that trades one strength for another, and keepsakes that work just by being carried. What an item does is a list of effects, each with a trigger (carried, worn, on a hit, on a kill, on being hurt). Most effects add [stat](/systems/stats) modifiers. Items are found in rooms, listed on the pause menu's inventory page, and saved.

## How it works

1. Every item is an `Item` resource (`actors/player/items/<kind>s/<id>.tres`) with an `id`, a title and description for the menus, a `kind`, a shop `price` and a list of `effects`.
2. The player's `Inventory` node (`PlayerInventory`, `actors/player/abilities/inventory.gd`) lists every item in `all`, remembers which ones are owned and which are worn, and enforces the slots. Every change emits `changed`.
3. `PlayerInventory.add(item)` gives the player an item and emits `Events.item_obtained(item)`. The HUD's `ItemToast` names it for a moment ("Found: Wolf fang").
4. The player's `ItemEffects` node (`PlayerItemEffects`, `actors/player/abilities/item_effects.gd`) runs the effects:
   - **Lasting effects** (`OWNED`, `EQUIPPED`) are worked out again whenever the inventory or health changes. Effects that should run and don't are started; effects that run and shouldn't are stopped.
   - **Event effects** (`ON_HIT`, `ON_KILL`, `ON_HURT`) of worn items start when the event happens. With a `duration` they stop again once it runs out; a new event restarts the clock instead of stacking.
   - Each effect runs under its own source, `item:<id>:<index>`, so its stat modifiers come off with `Stats.remove_source()`.
5. `ItemPickup` (`levels/objects/items/item_pickup.tscn`) is an item lying in a room. Interact takes it, once; its room remembers that through the `persistent` group.
6. The pause menu's **Inventory** page (`InventoryScreen`) lists owned items of one kind at a time. Left and right on the top row switch between charms, blades and keepsakes. Choosing a charm or blade wears it or takes it off. The focused item's description shows below.

### Kinds and slots

| Kind | Slots | Notes |
|---|---|---|
| `CHARM` | `PlayerStats.CHARM_SLOTS` (3, up to 8) | A charm needs a free slot. Pouches raise the stat |
| `BLADE` | 1 (`PlayerInventory.BLADE_SLOTS`) | Wearing a blade replaces the one worn |
| `KEEPSAKE` | none | Never worn. Its `OWNED` effects run while it is carried |

If the charm slot count drops (a save without the pouch), the last charms worn come off.

### Effects

`ItemEffect` (`actors/player/items/effects/item_effect.gd`) is the base. Every effect has:

| Field | Default | Meaning |
|---|---|---|
| `trigger` | `EQUIPPED` | `OWNED`: while carried. `EQUIPPED`: while worn. `ON_HIT`: a worn item, when a player hitbox lands a hit that rewards the attacker. `ON_KILL`: a worn item, when an enemy dies (`Events.enemy_killed`). `ON_HURT`: a worn item, when the player's hurtbox takes a hit |
| `below_health` | 1.0 | Only while health is below this fraction of the maximum. 1 is always |
| `chance` | 1.0 | Event triggers: chance that the event sets it off |
| `duration` | 0 | Event triggers: seconds until it stops. 0 never stops (one-shot effects) |

Two effects exist:

- **`StatEffect`**: adds its `modifiers` (`StatModifier` resources) while it runs, removes them on stop.
- **`RestoreEffect`**: gives `amount` health, spirit or currency once when it starts. Health isn't given to a dead player.

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
| Heavy edge | Blade | 600 | Damage +30%, dash cooldown +0.3 s |
| Thirsting edge | Blade | 600 | 30% chance to heal 3 on a hit, damage -10% |
| Guarding edge | Blade | 500 | Parry window +0.1 s, riposte window +0.25 s, max health -10 |
| Leather pouch | Keepsake | 500 | Charm slots +1 |
| Stitched pouch | Keepsake | 900 | Charm slots +1 |
| Spare gourd | Keepsake | 800 | Flasks +1 |

The test works room holds the wolf fang (near the start) and the leather pouch (behind the cracked wall). The rest are only reachable through the debug button for now.

### Saving

`PlayerInventory` is a global save system (`inventory`, see [Save system](/systems/save-system)): the owned and worn ids are saved when the player rests or dies. Ids the game no longer knows are dropped on load, so removing an item can't break a save.

### Debug

In debug builds the inventory page has a **Debug: get all items** button (`PlayerInventory.add_all()`). It adds every item without the HUD toast; they are saved like normal items the next time the game saves.

## Files

| File | Role |
|---|---|
| `actors/player/items/item.gd` | `Item` resource: id, text, kind, price, effects |
| `actors/player/items/effects/item_effect.gd` | `ItemEffect` base: trigger, health condition, chance, duration |
| `actors/player/items/effects/stat_effect.gd` | `StatEffect`: stat modifiers while it runs |
| `actors/player/items/effects/restore_effect.gd` | `RestoreEffect`: health, spirit or currency once |
| `actors/player/items/charms/`, `blades/`, `keepsakes/` | One `.tres` per item |
| `actors/player/abilities/inventory.gd` | `PlayerInventory`: every item, owned, worn, slots, saved |
| `actors/player/abilities/item_effects.gd` | `PlayerItemEffects`: starts and stops effects |
| `levels/objects/items/item_pickup.gd` / `.tscn` | `ItemPickup`: an item to pick up once |
| `ui/menus/inventory/inventory_screen.gd` | `InventoryScreen`: the pause menu's inventory page |
| `ui/hud/item_toast.gd` | `ItemToast`: names a new item in the HUD |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `PlayerStats.charm_slots` | 3 | Charm slots at the start (stat range 0 to 8) |
| `PlayerInventory.BLADE_SLOTS` | 1 | Blades worn at once (constant) |
| `ItemToast.show_time` | 2.0 | Seconds the item name stays fully visible |
| `ItemToast.fade_time` | 0.5 | Seconds it takes to fade out |
| `Item.price` / effect values | per item | See the item table |

## Extending

- **A new item:** create an `Item` `.tres` in the folder of its kind, give it a unique `id`, add effects, and add it to `Inventory.all` on the player scene (the inventory page lists items in that order). Never rename an `id` that has been saved.
- **A new effect type:** extend `ItemEffect` and override `start()` and `stop()`. `start()` gets the player and the effect's source.
- **A new trigger:** add it to `ItemEffect.Trigger`, connect the event in `PlayerItemEffects._ready()` and call `_fire()` with it.
- **Giving an item from a script** (a boss reward, a chest): `player.inventory.add(item)`.
- **Checking for an item** (a key for a door): `player.inventory.owns(item)`.

## Known limitations

- Hits from projectiles and blasts spawned after the player is ready don't set off `ON_HIT` effects, the same as for spirit.
- Event effects that are running when their item is taken off keep going until their duration runs out.
- Plain text rows in the default menu style: no item icons. Pickups are gold diamonds with no pickup animation.
