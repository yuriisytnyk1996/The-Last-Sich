# Upgrades

Permanent upgrades to max health, max spirit and the healing flasks. They are the player's long-term growth in survivability next to items and skills. Max health and max spirit come from upgrade shrines and fill the raised bar. Flasks come from empty flasks found in the world, and stronger flasks from a flask healer who takes living water and currency (see [Flask upgrades](#flask-upgrades)).

## How it works

1. **Shrines.** A `StatUpgrade` (`levels/objects/stat_upgrade.gd`) is placed in a room with a `kind` (health or spirit) and a `price`. The player stands at it and presses interact.
   - **Free** (`price` 0): the upgrade is given at once. These are meant as rewards for exploring, tucked away in secrets.
   - **Paid** (`price` above 0): the game pauses and an `UpgradeScreen` (`ui/menus/shop/upgrade_screen.gd`) shows what the upgrade adds, the price and the player's currency. "Leave" is focused first. "Offer" pays from the wallet and gives the upgrade; it reads "Not enough currency" and is disabled when the wallet is short.
2. **Upgrade.** `PlayerUpgrades.upgrade(kind)` (`actors/player/abilities/upgrades.gd`, the player's `Upgrades` child) counts one more upgrade of that kind and replaces that kind's FLAT modifier with one that matches the count, under a source of its own (`upgrades_health`, `upgrades_spirit`, `upgrades_flasks`, `upgrades_flask_heal`; see [Stats](/systems/stats)). Only that kind's modifier changes, and the new one is added before the old one is removed: taking the others away for a moment would lower their maximums and cut the current health, spirit or flasks down with them. Then it fills that bar: health to the new maximum, spirit to the new maximum (lowered by death marks, see [Death penalty](/systems/death-penalty)).
3. **Feedback.** `Events.player_upgraded(what)` makes the HUD's item toast show "Max health up" or "Max spirit up".
4. **Spent shrine.** The gem disappears and the prompt with it. The shrine is in the `persistent` group, so its room saves that it is spent.
5. **Saving.** `PlayerUpgrades` is a global save system: it saves how many upgrades of each kind the player has. Loading adds the modifiers again and fills nothing; health is full after a load anyway.

```
StatUpgrade ──interact──► (paid: UpgradeScreen ──Offer──► wallet.spend)
     │                                   │
     └──────────────► PlayerUpgrades.upgrade(kind)
                         │ stats: max_health +20 / max_spirit +15 (source "upgrades_health" / "upgrades_spirit")
                         │ fill the bar
                         └► Events.player_upgraded ──► ItemToast "Max health up"
```

On the map, paid shrines get a purple mark. Free shrines are secrets and get none.

## Flask upgrades

Two ways to make the [healing flasks](/systems/player#healing-flasks) better, both counted by `PlayerUpgrades` and saved with the other upgrades:

1. **More flasks.** An `EmptyFlask` (`levels/objects/flasks/empty_flask.gd`) lies in a room. Interact takes it: `upgrade(FLASKS)` adds `flask_step` (1) to `flask_count`. The new flask comes **empty**; the next rest point or respawn fills it. Taken once, saved by its room. `flask_count` is capped at 10 by `PlayerStats`.
2. **Stronger flasks.** A `FlaskHealer` (`levels/objects/flasks/flask_healer.gd`) is a healer's table. Interact pauses the game on a `FlaskHealerScreen` (`ui/menus/shop/flask_healer_screen.gd`), which shows how much more each flask would heal, the level, and the two things the healer asks for:
   - a **vial of living water**, a quest item (`Item.Kind.QUEST`). The first owned vial in the healer's `accepted` list is taken (`PlayerInventory.remove()`). There are five, one per level;
   - the **price** of the next level, from the healer's `prices` (400, 800, 1200, 1600, 2000).

   Each one the player lacks is shown in red and "Offer" reads "Not enough to offer". "Leave" is focused first. "Offer" takes both and calls `upgrade(FLASK_HEAL)`, which adds `flask_heal_step` (10) to `flask_heal`. After the last price the page only says the flasks are as strong as they get.

The healer saves nothing itself: its level is `PlayerUpgrades.count(FLASK_HEAL)`, so every healer in the world shares it. It stands in for a healer character until there are NPCs and dialogue. Healers get the purple upgrade mark on the map.

```
EmptyFlask ──interact──► upgrade(FLASKS)      flask_count +1 (empty until a rest)
FlaskHealer ──interact──► FlaskHealerScreen ──Offer──► wallet.spend(price)
                                                       inventory.remove(living water)
                                                       upgrade(FLASK_HEAL)  flask_heal +10
```

Starting at 2 flasks healing 20, five empty flasks and all five levels give 7 flasks healing 70.

The HUD flask pips change colour with each healing level, and get a bright cap from level 1 (see [HUD](/systems/hud#flask-counter)).

## Files

| File | Role |
|---|---|
| `actors/player/abilities/upgrades.gd` | `PlayerUpgrades`: upgrade counts, their stat modifiers, saved |
| `levels/objects/flasks/empty_flask.gd` | `EmptyFlask`: +1 flask, taken once |
| `levels/objects/flasks/flask_healer.gd` | `FlaskHealer`: stronger flasks for living water and currency |
| `ui/menus/shop/flask_healer_screen.gd` | `FlaskHealerScreen`: the healer's page |
| `actors/player/items/quest/living_water_*.tres` | The five vials of living water |
| `levels/objects/stat_upgrade.gd` | `StatUpgrade`: an upgrade shrine, free or paid, used once |
| `levels/objects/stat_upgrade.tscn` | Its scene: pedestal, gem (red for health, blue for spirit), prompt |
| `ui/menus/shop/upgrade_screen.gd` | `UpgradeScreen`: a paid shrine's page |

## Tuning

On the player's **`Upgrades`** child node (`PlayerUpgrades`):

| Value | Default | Effect |
|---|---|---|
| `health_step` | 20 | Max health added by each health upgrade (a fifth of the starting 100) |
| `spirit_step` | 15 | Max spirit added by each spirit upgrade (half of the starting 30) |
| `flask_step` | 1 | Flasks added by each empty flask |
| `flask_heal_step` | 10 | Health each flask heals more per flask healing level (half of the starting 20) |

On each **`StatUpgrade`**:

| Value | Default | Effect |
|---|---|---|
| `kind` | `HEALTH` | `HEALTH`, `SPIRIT`, `FLASKS` or `FLASK_HEAL` |
| `price` | 0 | Currency to pay. 0 is free |

Max health is capped at 500 by `PlayerStats`. Max spirit has no cap; level design sets how many spirit shrines there are.

On each **`FlaskHealer`**:

| Value | Default | Effect |
|---|---|---|
| `accepted` | the five living waters | Quest items taken, one per level |
| `prices` | 400, 800, 1200, 1600, 2000 | Currency per level. Its size is the number of levels |

In the test rooms: a free health shrine in the test vault's hidden alcove, a spirit shrine for 400 and a flask healer in the test house, and two empty flasks and two vials of living water just inside the test barracks.

## Extending

- **A new shrine:** drop `stat_upgrade.tscn` into a room's Logic scene, set `kind` and `price`.
- **More flasks or vials:** drop `empty_flask.tscn` into a room's Logic scene, or an `ItemPickup` with a living water. A new vial needs a `.tres` in `items/quest/`, a place in `Inventory.all` and in each healer's `accepted`, and one more entry in `prices`.
- **A new kind of upgrade** (damage): add it to the end of `PlayerUpgrades.Kind`, then to `STATS`, `kind_name()`, `KEYS`, `step()` and the gem colours in `StatUpgrade.GEM_COLORS`.
- **Rising prices:** set each paid shrine's `price` by hand, higher further into the game.

## Known limitations

- Placeholder art: a coloured gem on a pedestal.
- No sound or flash when an upgrade is given.
- The flask healer is a table, not a character, and has no dialogue.
- Placeholder art: an orange gourd for the empty flask, a table with a bowl and a flask for the healer.
