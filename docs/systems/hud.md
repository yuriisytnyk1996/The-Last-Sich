# HUD

The on-screen gameplay interface: the player's health bar and their healing flasks. The HUD never references the player: it only listens to the `Events` bus, so rooms, menus and the player can change without touching it.

## How it works

1. `PlayerDamage` forwards the player's `Health.health_changed` to `Events.player_health_changed(current, maximum)`.
2. On spawn it also sends the starting value once, deferred, because the HUD can come after the player in the scene tree and wouldn't be listening yet.
3. `HealthBar` (`ui/hud/health_bar.gd`) receives it and redraws.

The bar has four layers, drawn back to front with `_draw()`:

| Layer | Colour | Shows |
|---|---|---|
| Frame | `frame_color` | Outline, `border` px thick |
| Empty | `empty_color` | Missing health |
| Loss | `loss_color` | Health that was just lost (or is about to be healed) |
| Fill | `fill_color` | Current health |

**Taking damage:** the fill drops to the new value at once, so the player sees the real number immediately. The pale loss segment stays where the fill was for `loss_delay`, then drains down at `loss_drain_speed`. This makes the size of each hit readable, even for several hits in a row.

**Healing:** the loss segment jumps up to the new value as a preview, and the fill rises to meet it at `heal_fill_speed`. On respawn this refills the bar from empty.

**Width grows with max health:** the bar is `max health × pixels_per_point` wide, so a max health upgrade visibly lengthens it.

Widths are rounded down to whole pixels so the bar edge stays crisp. The bar only processes while it is animating.

During hit-stop the bar freezes with the rest of the game, which holds the loss segment still at the moment of impact.

### Flask counter

`FlaskCounter` (`ui/hud/flask_counter.gd`) sits under the health bar and draws one pip per healing flask: `full_color` while the flask is full, `empty_color` once it's used, each with a `frame_color` outline. It listens to `Events.player_flasks_changed(current, maximum)`, which `PlayerFlasks` sends on every change and once on spawn (deferred). More flasks mean more pips. See [Healing flasks](/systems/player#healing-flasks).

Feedback:

- **Drinking:** the pip that was just used shows `flash_color` for `drink_flash_time` before going dim.
- **No flasks left:** pressing heal sends `Events.player_flasks_empty`; the pips shake sideways by `empty_shake_distance` for `empty_shake_time`, with `warning_color` frames.

## Files

| File | Role |
|---|---|
| `ui/hud/hud.tscn` | `CanvasLayer` with the HUD widgets. Instance it once per room |
| `ui/hud/health_bar.gd` | Health bar drawing and animation |
| `ui/hud/flask_counter.gd` | Healing flask pips |
| `actors/player/abilities/flasks.gd` | Reports the player's flasks to `Events` |
| `ui/hud/currency_counter.gd` | Currency number |
| `ui/hud/spirit_bar.gd` | Spirit bar with the locked part |
| `ui/hud/death_mark_counter.gd` | Death mark pips |
| `actors/player/player_damage.gd` | Forwards player health to `Events` |

## Tuning

On the `HealthBar` node:

| Value | Default | Effect |
|---|---|---|
| `pixels_per_point` | 12 | Bar width per point of max health (px) |
| `bar_height` | 4 | Inner bar height (px) |
| `border` | 1 | Frame thickness (px) |
| `loss_delay` | 0.4 | Seconds the loss segment holds before draining |
| `loss_drain_speed` | 4.0 | Loss segment drain speed (health points/s) |
| `heal_fill_speed` | 6.0 | Fill rise speed when healing (health points/s) |
| `frame_color` | `#1a1018` | Outline |
| `empty_color` | `#3b2730` | Missing health |
| `loss_color` | `#e8d8b0` | Just-lost / incoming health |
| `fill_color` | `#b8323a` | Current health |

On the `FlaskCounter` node:

| Value | Default | Effect |
|---|---|---|
| `pip_size` | (5, 7) | Inner size of one pip (px) |
| `spacing` | 2 | Gap between pips (px) |
| `border` | 1 | Frame thickness around each pip (px) |
| `drink_flash_time` | 0.25 | Seconds a just-drunk flask flashes |
| `empty_shake_time` | 0.3 | Seconds the pips shake when heal is pressed with none left |
| `empty_shake_distance` | 2 | Sideways shake (px) |
| `frame_color` | `#1a1018` | Outline |
| `empty_color` | `#3b2730` | Used flask |
| `full_color` | `#d89a3a` | Full flask |
| `flash_color` | `#fff2c8` | Flask that was just drunk |
| `warning_color` | `#b8323a` | Frames while shaking (no flasks left) |

### Spirit bar and death marks

`SpiritBar` (`ui/hud/spirit_bar.gd`) sits right under the health bar. It is as wide as spirit without death marks (`full_maximum × pixels_per_point`). The part death marks take away is drawn in `locked_color` at the right end, so every death visibly shortens what can be filled. It listens to `Events.player_spirit_changed(current, maximum, full_maximum)`. See [Spirit](/systems/spirit).

`DeathMarkCounter` (`ui/hud/death_mark_counter.gd`) draws one small purple pip per death mark to the right of the spirit bar, nothing while there are none. It listens to `Events.death_marks_changed(count)`. See [Death penalty](/systems/death-penalty).

| Value | Default | Effect |
|---|---|---|
| `SpiritBar.pixels_per_point` | 2.0 | Bar width per point of spirit (px) |
| `SpiritBar.bar_height` | 3 | Inner bar height (px) |
| `SpiritBar.border` | 1 | Frame thickness (px) |
| `SpiritBar.frame_color` | `#1a1018` | Outline |
| `SpiritBar.empty_color` | `#2a2440` | Spirit not yet filled |
| `SpiritBar.fill_color` | `#6f7fd8` | Current spirit |
| `SpiritBar.locked_color` | `#4a2050` | Spirit locked by death marks |
| `DeathMarkCounter.pip_size` | (3, 5) | Inner size of one pip (px) |
| `DeathMarkCounter.spacing` | 1 | Gap between pips (px) |
| `DeathMarkCounter.pip_color` | `#8a3a90` | Pip |
| `DeathMarkCounter.frame_color` | `#1a1018` | Pip outline |

### Currency counter

`CurrencyCounter` (`ui/hud/currency_counter.gd`) is a `Label` under the flasks showing the currency the player carries. It listens to `Events.player_currency_changed(amount)` and flashes `flash_color` for `flash_time` when the amount goes up. Tuning is on the [Currency](/systems/currency#tuning) page.

## Extending

- **New HUD widget** (ability charges): add a `Control` under `HUD` in `ui/hud/hud.tscn`, add a global signal to `Events` for the value it shows, and have the owning system emit it. Send the starting value deferred, the same way as health.
- **Another bar** (a boss bar, for example): reuse the same layered approach, driven by its own signal.

## Known limitations

- Placeholder look: plain rectangles, no sprite frame.
- The HUD lives in the `World` scene, so it survives room changes.
- No layout for mobile touch controls yet.
