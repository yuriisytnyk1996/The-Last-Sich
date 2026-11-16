# Stats

Stats are the named numbers that items, skills and effects are allowed to change: max health, flasks, damage, resistances, spirit, parry timing, dash cooldown. Each stat has a base value plus modifiers tagged with the source that added them. Code that uses a stat reads the final value instead of its own `@export`, so a new upgrade only adds a modifier and nothing else needs wiring.

## How it works

`Stats` (`components/stats/stats.gd`) is a node an actor carries. The player's is `PlayerStats` (`actors/player/player_stats.gd`), the `Stats` child of the player.

1. **Defining.** A subclass declares its stats in `_define_stats()` with `define(stat, base, min, max)`. This runs once, the first time anything reads a stat, so readers never depend on node order. `PlayerStats` takes the bases from its `@export` values.
2. **Modifiers.** A `StatModifier` (`components/stats/stat_modifier.gd`) is a resource: a stat name, a kind and a value. `add_modifier(modifier, source)` adds it under a source such as an item id. `remove_source(source)` takes back everything that source added. `add_timed_modifier(modifier, source, seconds)` removes it on its own after that much game time (paused time doesn't count).
3. **Value.** `get_value(stat)` is `(base + every FLAT) × (1 + every PERCENT)`, clamped to the stat's range. Percents add up instead of multiplying, so two +20 % modifiers make +40 %. A stat the node doesn't have returns the `fallback` argument.
4. **Changes.** Every add or remove emits `stat_changed(stat)`. Readers that hold a value (health, flasks, spirit) update right away. The rest read the stat each time they need it.

```
StatModifier (max_health +20, FLAT) ──add_modifier(.., &"iron_ring")──► Stats
                                                                        │ stat_changed(max_health)
                                                                        ▼
                                                        Health: max 100 → 120, current stays
```

### Who reads what

| Stat | Constant | Read by | Effect |
|---|---|---|---|
| `max_health` | `Stats.MAX_HEALTH` | `Health` (when its `stats` is set) | Maximum health. A higher maximum leaves current health as it is, a lower one cuts it |
| `damage` | `Stats.DAMAGE` | `Hitbox.get_damage()` through `attacker_stats` | Multiplier for every hit the actor deals |
| `normal_resist`, `contact_resist`, `fire_resist`, `poison_resist` | `Stats.*_RESIST` | `Health.take_hit()` | Fraction of damage of that [element](/systems/combat#elements) ignored |
| `flask_count` | `PlayerStats.FLASK_COUNT` | `PlayerFlasks` | Flasks when full. Fewer takes flasks away, more adds empty ones the next refill fills |
| `flask_heal` | `PlayerStats.FLASK_HEAL` | `PlayerFlasks` | Health restored by one flask |
| `max_spirit` | `PlayerStats.MAX_SPIRIT` | `PlayerSpirit` | Maximum spirit before death marks |
| `spirit_per_hit` | `PlayerStats.SPIRIT_PER_HIT` | `PlayerSpirit` | Spirit per landed hit |
| `parry_window` | `PlayerStats.PARRY_WINDOW` | `PlayerParry` | Seconds the guard is up |
| `riposte_window` | `PlayerStats.RIPOSTE_WINDOW` | `PlayerParry` | Seconds to press attack after a parry |
| `dash_cooldown` | `PlayerStats.DASH_COOLDOWN` | `Player.start_dash()` | Seconds before the next dash |

### Damage and resistance

A hit's damage goes through two steps:

1. **Attacker:** `Hitbox.get_damage()` is `damage × attacker_stats.damage`, rounded, at least 1 unless it comes out at 0. Without `attacker_stats` the base damage is used. `PlayerStats` sets itself as `attacker_stats` on every hitbox under the player when it is ready. Projectiles and blasts are spawned later, so `PlayerProjectile.launch()` takes the stats from a `Player` thrower and `PlayerBlast.spawn()` takes them as an argument.
2. **Receiver:** `Health.take_hit(hitbox)` lowers the damage by the receiver's resistance to the hit's element: `round(damage × (1 − resist))`, at least 1. A resistance of 1 or more blocks the hit completely. A `Health` without `stats` takes the full damage. `Hurtbox` calls `take_hit()` for every hit it accepts.

Death-mark penalties stay as factors on `PlayerSpirit` and `PlayerWallet` (`max_factor`, `gain_factor`), not modifiers. The HUD needs the maximum without them to draw the locked part of the spirit bar.

### Scale

Health and damage use a 100-point scale: the player has 100 health, a basic hit from an enemy or hazard does 20, a side slash does 20. Whole numbers this size leave room for percent bonuses and resistances: a 20 % resistance turns a 20-damage hit into 16.

### Enemy stats

Every enemy has a **`Stats`** child node (`EnemyStats`, `actors/enemies/enemy_stats.gd`) with `max_health`, `damage` (a multiplier for all its attacks, contact damage and projectiles included) and the four resistances. Its `Health` reads the maximum from it. The raider has 60 health, the musketeer 40. Hazards (traps, turrets, poison zones) have no stats and deal their hitbox's base damage.

## Files

| File | Role |
|---|---|
| `components/stats/stats.gd` | `Stats`: definitions, modifiers by source, timed modifiers, shared stat names |
| `components/stats/stat_modifier.gd` | `StatModifier`: one FLAT or PERCENT change to one stat, a resource |
| `actors/player/player_stats.gd` | `PlayerStats`: the player's stats and their base values |
| `actors/enemies/enemy_stats.gd` | `EnemyStats`: an enemy's health, damage multiplier and resistances |

## Tuning

Base values, on the player's **`Stats`** child node (`PlayerStats`):

| Group | Value | Default | Range | Effect |
|---|---|---|---|---|
| Health | `max_health` | 100 | 1 to 500 | Starting and maximum health |
| Health | `flask_count` | 2 | 0 to 10 | Flasks carried when all are full |
| Health | `flask_heal` | 40 | 0 and up | Health restored by one flask |
| Offense | `damage` | 1.0 | 0 and up | Multiplier for every player hitbox and projectile |
| Defense | `normal_resist` | 0 | 0 to 1 | Fraction of NORMAL damage ignored |
| Defense | `contact_resist` | 0 | 0 to 1 | Fraction of CONTACT damage ignored |
| Defense | `fire_resist` | 0 | 0 to 1 | Fraction of FIRE damage ignored |
| Defense | `poison_resist` | 0 | 0 to 1 | Fraction of POISON damage ignored |
| Spirit | `max_spirit` | 30 | 0 and up | Maximum spirit without death marks |
| Spirit | `spirit_per_hit` | 2 | 0 and up | Spirit per landed hit |
| Timing | `parry_window` | 0.25 | 0.05 and up | Seconds the guard is up after the press |
| Timing | `riposte_window` | 0.5 | 0.05 and up | After a parry, seconds to press attack for a riposte |
| Timing | `dash_cooldown` | 0.4 | 0 and up | Seconds before the next dash |

Base values on each enemy's **`Stats`** node (`EnemyStats`):

| Value | Default | Raider | Musketeer | Effect |
|---|---|---|---|---|
| `max_health` | 60 | 60 | 40 | Starting and maximum health |
| `damage` | 1.0 | 1.0 | 1.0 | Multiplier for every hit the enemy deals |
| `normal_resist`, `contact_resist`, `fire_resist`, `poison_resist` | 0 | 0 | 0 | Fraction of damage of that element ignored (0 to 1) |

## Extending

- **An item or skill that changes a stat:** make a `StatModifier` `.tres` (or call `StatModifier.create()`), then `player.stats.add_modifier(modifier, &"item_id")` when it is gained and `player.stats.remove_source(&"item_id")` when it is lost.
- **A temporary buff:** `player.stats.add_timed_modifier(modifier, &"buff_id", seconds)`.
- **A new stat:** add a constant and an `@export` base to `PlayerStats` (or `Stats` if every actor can have it), `define()` it in `_define_stats()`, read it with `get_value()` where it is used, and add it to the tables above.
- **Stats for an enemy:** every enemy has an `EnemyStats` node, see below. A new kind of actor gets a `Stats` subclass node and points its `Health.stats` at it. `Stats._ready()` sets itself as `attacker_stats` on every hitbox in the owner's scene; projectiles it spawns need it set by hand, as `MusketShot` does.

## Known limitations

- Modifiers aren't saved. Whatever adds them (items, skills) has to add them again after a load.
- Attack speed, run speed and critical hits aren't stats yet.
