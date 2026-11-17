# Upgrades

Permanent upgrades to max health and max spirit, found at upgrade shrines around the world. They are the player's long-term growth in survivability next to items and skills: each one raises a bar for good and fills it.

## How it works

1. **Shrines.** A `StatUpgrade` (`levels/objects/stat_upgrade.gd`) is placed in a room with a `kind` (health or spirit) and a `price`. The player stands at it and presses interact.
   - **Free** (`price` 0): the upgrade is given at once. These are meant as rewards for exploring, tucked away in secrets.
   - **Paid** (`price` above 0): the game pauses and an `UpgradeScreen` (`ui/menus/shop/upgrade_screen.gd`) shows what the upgrade adds, the price and the player's currency. "Leave" is focused first. "Offer" pays from the wallet and gives the upgrade; it reads "Not enough currency" and is disabled when the wallet is short.
2. **Upgrade.** `PlayerUpgrades.upgrade(kind)` (`actors/player/abilities/upgrades.gd`, the player's `Upgrades` child) counts one more upgrade of that kind and replaces its modifiers with FLAT ones that match the counts, under the `upgrades` source (see [Stats](/systems/stats)). Then it fills that bar: health to the new maximum, spirit to the new maximum (lowered by death marks, see [Death penalty](/systems/death-penalty)).
3. **Feedback.** `Events.player_upgraded(what)` makes the HUD's item toast show "Max health up" or "Max spirit up".
4. **Spent shrine.** The gem disappears and the prompt with it. The shrine is in the `persistent` group, so its room saves that it is spent.
5. **Saving.** `PlayerUpgrades` is a global save system: it saves how many upgrades of each kind the player has. Loading adds the modifiers again and fills nothing; health is full after a load anyway.

```
StatUpgrade ──interact──► (paid: UpgradeScreen ──Offer──► wallet.spend)
     │                                   │
     └──────────────► PlayerUpgrades.upgrade(kind)
                         │ stats: max_health +20 / max_spirit +15 (source "upgrades")
                         │ fill the bar
                         └► Events.player_upgraded ──► ItemToast "Max health up"
```

On the map, paid shrines get a purple mark. Free shrines are secrets and get none.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/upgrades.gd` | `PlayerUpgrades`: upgrade counts, their stat modifiers, saved |
| `levels/objects/stat_upgrade.gd` | `StatUpgrade`: an upgrade shrine, free or paid, used once |
| `levels/objects/stat_upgrade.tscn` | Its scene: pedestal, gem (red for health, blue for spirit), prompt |
| `ui/menus/shop/upgrade_screen.gd` | `UpgradeScreen`: a paid shrine's page |

## Tuning

On the player's **`Upgrades`** child node (`PlayerUpgrades`):

| Value | Default | Effect |
|---|---|---|
| `health_step` | 20 | Max health added by each health upgrade (a fifth of the starting 100) |
| `spirit_step` | 15 | Max spirit added by each spirit upgrade (half of the starting 30) |

On each **`StatUpgrade`**:

| Value | Default | Effect |
|---|---|---|
| `kind` | `HEALTH` | `HEALTH` or `SPIRIT` |
| `price` | 0 | Currency to pay. 0 is free |

Max health is capped at 500 by `PlayerStats`. Max spirit has no cap; level design sets how many spirit shrines there are.

In the test rooms: a free health shrine in the test vault's hidden alcove, and a spirit shrine for 400 in the test house.

## Extending

- **A new shrine:** drop `stat_upgrade.tscn` into a room's Logic scene, set `kind` and `price`.
- **A new kind of upgrade** (flasks, damage): add it to `PlayerUpgrades.Kind`, `STATS`, `step()`, `kind_name()`, the save data and the gem colours in `StatUpgrade.GEM_COLORS`.
- **Rising prices:** set each paid shrine's `price` by hand, higher further into the game.

## Known limitations

- Placeholder art: a coloured gem on a pedestal.
- No sound or flash when an upgrade is given.
