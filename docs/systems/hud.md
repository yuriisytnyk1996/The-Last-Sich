# HUD

The on-screen gameplay interface. For now it holds the player's health bar. The HUD never references the player: it only listens to the `Events` bus, so rooms, menus and the player can change without touching it.

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

## Files

| File | Role |
|---|---|
| `ui/hud/hud.tscn` | `CanvasLayer` with the HUD widgets. Instance it once per room |
| `ui/hud/health_bar.gd` | Health bar drawing and animation |
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

## Extending

- **New HUD widget** (currency, ability charges): add a `Control` under `HUD` in `ui/hud/hud.tscn`, add a global signal to `Events` for the value it shows, and have the owning system emit it. Send the starting value deferred, the same way as health.
- **Another bar** (a boss bar, for example): reuse the same layered approach, driven by its own signal.

## Known limitations

- Placeholder look: plain rectangles, no sprite frame.
- The HUD is instanced by hand in each room. Once room transitions exist it should move to a persistent layer that survives room changes.
- No layout for mobile touch controls yet.
