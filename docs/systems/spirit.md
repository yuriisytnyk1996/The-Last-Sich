# Spirit

Spirit is a resource the player builds up by fighting. It will pay for spirit abilities later. Death marks lower both its maximum and how fast it fills, see [Death penalty](/systems/death-penalty).

## How it works

`PlayerSpirit` (`actors/player/abilities/spirit.gd`) lives on the player.

1. On `_ready()` it connects to `hit_landed` on every `Hitbox` under the player (the attack swings and the riposte).
2. Each landed hit adds `per_hit × gain_factor`, times `heavy_multiplier` for a hit with a `HEAVY` reaction (the riposte). Hits on the training dummy count too.
3. Spirit never goes past `get_max()`, which is `full_max × max_factor`.
4. Every change goes out as `Events.player_spirit_changed(current, maximum, full_maximum)`. The HUD's `SpiritBar` draws it, with the part death marks take away shown as locked.

`DeathPenalty` sets `max_factor` and `gain_factor` from the number of death marks. Lowering `max_factor` also cuts the current spirit down to the new maximum. Recovering a death mark adds part of the maximum through `add()`, which ignores `gain_factor`.

Spirit is earned in fights, not handed out:

- It starts **empty** on every new game and every load. It isn't saved.
- **Resting doesn't refill it.**
- **Dying keeps it**, apart from the lower maximum the new death mark brings.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/spirit.gd` | `PlayerSpirit`: amount, gain from hits, factors set by the death penalty |
| `ui/hud/spirit_bar.gd` | HUD bar, see [HUD](/systems/hud#spirit-bar-and-death-marks) |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `full_max` | 30.0 | Maximum spirit without death marks |
| `per_hit` | 2.0 | Spirit per landed hit |
| `heavy_multiplier` | 2.0 | Multiplier for hits with a `HEAVY` reaction |

## Extending

- **A spirit ability:** check `spirit.current`, then lower it and send the change. Add a `spend(amount) -> bool` to `PlayerSpirit` with the first one.
- **Max spirit upgrades:** raise `full_max`, then assign `max_factor` again (its setter announces the change), and the bar grows with it.
- **Other gains** (finishing moves, items): call `add()`.

## Known limitations

- Nothing spends spirit yet.
- Placeholder bar: plain rectangles.
