# Spirit

Spirit is a resource the player builds up by fighting. The [ranged bolt](/systems/skills) spends it. Death marks lower both its maximum and how fast it fills, see [Death penalty](/systems/death-penalty).

## How it works

`PlayerSpirit` (`actors/player/abilities/spirit.gd`) lives on the player.

1. On `_ready()` it connects to `hit_landed` on every `Hitbox` under the player (the attack swings and the riposte).
2. Each landed hit adds `spirit_per_hit × gain_factor`, times `heavy_multiplier` for a hit with a `HEAVY` reaction (the riposte). Hits on the training dummy count too. Hits on a hurtbox with `rewards_attacker` off (crates, cracked walls, see [Environment](/systems/environment#breakables)) don't.
3. Spirit never goes past `get_max()`, which is `full_max() × max_factor`. `full_max()` and `spirit_per_hit` are [stats](/systems/stats) (`max_spirit`, `spirit_per_hit`), so items can raise them.
4. Every change goes out as `Events.player_spirit_changed(current, maximum, full_maximum)`. The HUD's `SpiritBar` draws it, with the part death marks take away shown as locked.

`DeathPenalty` sets `max_factor` and `gain_factor` from the number of death marks. Lowering `max_factor` also cuts the current spirit down to the new maximum. Recovering a death mark adds part of the maximum through `add()`, which ignores `gain_factor`.

Spirit is earned in fights. The **Icon lamp** keepsake (`PlayerUnlocks.REST_SPIRIT`) makes rest points top it up:

| Moment | Without the Icon lamp | With it |
|---|---|---|
| New game or load | Empty. It isn't saved | Empty. It isn't saved |
| Rest at a rest point | Unchanged | Full (`PlayerSpirit.fill()`) |
| Respawn after death | **Empty** | Full, up to the lower maximum the new death mark brings |
| Changing rooms | Kept | Kept |

`RestPoint` calls `fill()` when the player has the unlock. After a death, `World` calls `PlayerSpirit.restore_after_death()` once the player is back, after `DeathPenalty` has set the new `max_factor`, so "full" already counts the new mark. Spirit isn't saved because it would be thrown away on load anyway: a loaded game always starts with it empty.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/spirit.gd` | `PlayerSpirit`: amount, gain from hits, factors set by the death penalty, `fill()` and `restore_after_death()` |
| `levels/objects/rest_point.gd` | Fills spirit on rest with the unlock |
| `levels/world.gd` | Calls `restore_after_death()` after a death respawn |
| `actors/player/items/keepsakes/icon_lamp.tres` | The keepsake that grants `rest_spirit` |
| `ui/hud/spirit_bar.gd` | HUD bar, see [HUD](/systems/hud#spirit-bar-and-death-marks) |

## Tuning

The maximum (`max_spirit`, 30) and the gain per hit (`spirit_per_hit`, 2) are on the player's `Stats` node, see [Stats](/systems/stats#tuning). On the `Spirit` node:


| Value | Default | Effect |
|---|---|---|
| `heavy_multiplier` | 2.0 | Multiplier for hits with a `HEAVY` reaction |

## Extending

- **A spirit ability:** call `spirit.spend(amount)` and only go ahead when it returns true, as `PlayerRangedAttack` does.
- **Max spirit upgrades:** add a `max_spirit` modifier to the player's stats. Spirit announces the change and the bar grows with it.
- **Other gains** (finishing moves, items): call `add()`.

## Known limitations

- Placeholder bar: plain rectangles.
