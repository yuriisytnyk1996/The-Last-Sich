# Dumas

Dumas are songs the player sings for [spirit](/systems/spirit). They are [items](/systems/inventory) of their own kind, worn one at a time, and sung with the `duma` button: a rising aura, then the duma goes off. Some strike at once (pillars of fire, a thunderbolt, a volley, a stunning burst); others last a while (a ring of sabres, heavy strikes). While one lasts, no other can be sung.

## How it works

```
Idle / Run ──duma pressed──► can sing? ──no──► Events.spirit_short (spirit bar flashes)
                                  │ yes
                                  ▼
                            Duma state: planted, aura rises
                                  │ cast_point
                                  ▼
            PlayerDumas.begin(): spend cost(), ItemEffects.use(item)
                                  │ recovery
                                  ▼
                              Idle / Run
     lasting effects run for duration + DUMA_DURATION ──► running (HUD line shrinks)
```

1. A duma is an `Item` with `kind = DUMA` (`actors/player/items/dumas/<id>.tres`). It has a `spirit_cost` and effects with the `ON_USE` trigger. There is one duma slot; wearing another duma replaces the worn one. See [Inventory](/systems/inventory#kinds-and-slots).
2. In Idle or Run, a press of `duma` asks `PlayerDumas.wants()` (`actors/player/abilities/dumas.gd`). It can sing when a duma is worn, none is running and the player has at least `cost()` spirit: the duma's `spirit_cost` plus the `duma_cost` [stat](/systems/stats). Otherwise it emits `Events.spirit_short` and the spirit bar flashes red. A press while a duma is running does nothing.
3. The **Duma** state (`actors/player/states/duma.gd`) plants the player on the ground with no control. The `DumaAura` placeholder fades in over `cast_point`.
4. At the cast point it calls `PlayerDumas.begin()`. The spirit is spent, and `PlayerItemEffects.use(item, extra)` starts every `ON_USE` effect of the duma. Effects with a `duration` run for that long plus the `duma_duration` stat, then stop on their own.
5. The aura flashes and fades during `recovery`, then the player is back in Idle or Run. A hit before the cast point interrupts the cast and nothing is spent. Walking off a ledge drops into Fall.
6. While the longest lasting effect runs, the duma is **running** (`PlayerDumas.is_running()`). Each frame `Events.duma_time_changed(fraction_left)` reports the time left, and the [HUD](/systems/hud#spirit-bar-and-death-marks) draws it as a line under the spirit bar. A duma with only instant effects never runs.
7. Death ends a running duma at once (`PlayerDumas.end()`, on `Health.died`), stopping its effects.
8. **Swapping while one runs:** the running duma is the one sung, not the one worn. Wearing another duma, or taking every duma off, doesn't stop it: its effects (a sabre ring, heavy strikes) keep going until their time runs out, and `duma` still does nothing until then. The newly worn duma can be sung once it ends. `PlayerItemEffects` stops `ON_USE` effects by their timer whatever is worn.

### Duma effects

Dumas are built from [item effects](/systems/inventory#effects) with the `ON_USE` trigger. Four effect types exist for them; attacks they spawn are scaled by `PlayerDumas.strength()`, the `duma_strength` stat, on top of the player's `damage` stat.

- **`BlastRowEffect`**: a row of `PlayerBlast`s along the ground from the player's feet, one after another. The first goes off `offset` px in front, the next ones `spacing` further each, spread evenly over `spread_time`; `both_sides` sends a second row behind. A wall ends the row (a ray at `WALL_CHECK_HEIGHT` above the feet). `count` 1 with `offset` 0 is a single blast on the player.
- **`VolleyEffect`**: `shots` `PlayerProjectile`s forward from the chest (`muzzle`), `interval` apart, each after the first up to `spread` px higher or lower at random.
- **`SummonEffect`**: puts a scene next to the player for the effect's `duration`, calling its `follow(player)` before adding it and its `dismiss()` when the effect stops. Used for the `SabreRing`.
- **`HeavyStrikesEffect`**: every swing hitbox under `Visual/Attacks` deals HEAVY hits while it runs (longer stagger, more knockback, double spirit); their own reaction comes back when it stops.

The existing `StatEffect` and `RestoreEffect` work with `ON_USE` too: the Iron Hand pairs `HeavyStrikesEffect` with a `StatEffect` for damage.

**Sabre ring** (`actors/player/attacks/sabre_ring.gd`): its `Hitbox` children circle the player's chest, opening from nothing to `radius` over `open_time`. Each sabre hits enemies it passes, and is switched off for one frame every `rehit_time` so an enemy that stays inside is hit again. Enemy shots (`EnemyProjectile`) that touch a sabre are destroyed. On `dismiss()` the ring closes over `close_time`, then frees itself. A room change frees it at once.

**Stunning hits:** the Calm Sea's `StunBurst` has `Hitbox.stuns` on. An enemy that flinches is stunned by it as if parried (`EnemyDamage.stun_from()`), see [Enemies](/systems/enemies#stun). Bosses don't flinch, so they only take the damage.

### Dumas

| Duma | Cost | Price | Effect |
|---|---|---|---|
| Duma of the Burning Steppe | 15 | 600 | 8 `FirePillar`s march forward (24 px apart, from 24 px, over 0.6 s), 30 FIRE damage each |
| Duma of the Black Sea Storm | 15 | 600 | 4 `FirePillar`s on each side at once (28 px apart, from 20 px, over 0.4 s) |
| Duma of the Thunderbolt | 20 | 700 | A `ThunderBeam` (28 × 200 px) on the player: 70 damage, HEAVY |
| Duma of the Three Brothers | 10 | 450 | 3 `DumaShot`s forward, 0.15 s apart, 30 damage each |
| Duma of the Calm Sea | 15 | 550 | A `StunBurst` (144 × 56 px) around the player: 10 damage, stuns |
| Duma of the Sabre Ring | 20 | 800 | 3 sabres circle the player for 15 s, 15 damage per hit, destroy enemy shots |
| Duma of the Iron Hand | 20 | 800 | For 20 s every swing is HEAVY and damage is +25% |

All seven lie in the test room, past the pit east of the training dummy.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/dumas.gd` | `PlayerDumas`: the button, cost, `begin()`, running time, `end()` |
| `actors/player/states/duma.gd` | Duma: the planted cast with the aura |
| `actors/player/items/dumas/` | One `.tres` per duma |
| `actors/player/items/effects/blast_row_effect.gd` | `BlastRowEffect`: a row of blasts along the ground |
| `actors/player/items/effects/volley_effect.gd` | `VolleyEffect`: a few shots forward |
| `actors/player/items/effects/summon_effect.gd` | `SummonEffect`: a scene beside the player while it runs |
| `actors/player/items/effects/heavy_strikes_effect.gd` | `HeavyStrikesEffect`: HEAVY swings while it runs |
| `actors/player/attacks/sabre_ring.gd` / `.tscn` | `SabreRing`: the circling sabres |
| `actors/player/attacks/fire_pillar.tscn`, `thunder_beam.tscn`, `stun_burst.tscn` | `PlayerBlast` scenes for dumas |
| `actors/player/attacks/duma_shot.tscn` | `PlayerProjectile` for the Three Brothers |

## Tuning

Duma state (`StateMachine/Duma`):

| Value | Default | Effect |
|---|---|---|
| `cast_point` | 0.4 | Seconds from the press to the cast point, where spirit is spent |
| `recovery` | 0.35 | Seconds held after the cast point |

Stats (`PlayerStats`, see [Stats](/systems/stats)):

| Value | Default | Effect |
|---|---|---|
| `duma_cost` | 0 | Spirit added to every duma's cost (below 0 makes them cheaper, never below 0) |
| `duma_duration` | 0 | Seconds added to every lasting duma effect |
| `duma_strength` | 1.0 | Multiplier for the damage of duma attacks |

`BlastRowEffect`:

| Value | Default | Effect |
|---|---|---|
| `count` | 8 | Blasts in a row |
| `offset` | 24 | Distance from the player to the first blast (px) |
| `spacing` | 24 | Distance between blasts (px) |
| `spread_time` | 0.6 | Seconds from the first blast to the last |
| `both_sides` | false | Also a row behind |
| `shake` | 0.3 | Camera shake when the row starts |

`VolleyEffect`:

| Value | Default | Effect |
|---|---|---|
| `shots` | 3 | Shots fired |
| `interval` | 0.15 | Seconds between shots |
| `spread` | 6 | Random height change of later shots (px) |
| `muzzle` | (12, -18) | Where shots start, facing right (px) |

`SabreRing`:

| Value | Default | Effect |
|---|---|---|
| `radius` | 28 | Ring radius when open (px) |
| `open_time` / `close_time` | 0.5 / 0.4 | Seconds to open and close |
| `turns_per_second` | 0.8 | Spin speed |
| `rehit_time` | 0.5 | Seconds before a sabre can hit the same enemy again |
| `height` | 16 | Centre above the feet (px) |
| `follow_speed` | 12 | How tightly it follows the player |

Attack scenes:

| Scene | Damage | Size (px) | Notes |
|---|---|---|---|
| `FirePillar` | 30 | 16 × 56 | FIRE, knocks up, on for 0.25 s |
| `ThunderBeam` | 70 | 28 × 200 | HEAVY, knocks up, shake 0.9, on for 0.3 s |
| `StunBurst` | 10 | 144 × 56 | LIGHT, `stuns`, shake 0.5, on for 0.2 s |
| `DumaShot` | 30 | 12 × 4 | 360 to 420 px/s, 0.6 s |
| `SabreRing` sabre | 15 | 10 × 10 | Three of them |

## Extending

- **A new duma:** create an `Item` `.tres` in `actors/player/items/dumas/` with `kind = DUMA`, a `spirit_cost`, a description that names the cost, a lore, and effects with `trigger = ON_USE`. Add it to `Inventory.all` on the player scene. A lasting duma needs a `duration` on its effects.
- **A new kind of effect:** extend `ItemEffect`, override `start()` (and `stop()` if it lasts). Scale any damage by `player.dumas.strength()`. Spawn attacks under `player.get_parent()`, as the other effects do.
- **A charm that changes dumas:** a `StatEffect` on `duma_cost`, `duma_duration` or `duma_strength`.

## Known limitations

- Placeholder rectangles for the aura, pillars, beam, burst, shots and sabres. No singing sound.
- Hits from duma attacks don't fill spirit and don't set off `ON_HIT` item effects (they are spawned after the player is ready).
- Blasts of a row still waiting to go off are not cancelled by a room change or death.
- Only Idle and Run can start a duma; a press during a swing or in the air is ignored without a flash.
