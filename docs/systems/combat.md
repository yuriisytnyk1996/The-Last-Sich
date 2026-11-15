# Combat

Three small components in `components/combat/` handle all damage in the game: a **Hitbox** deals it, a **Hurtbox** receives it, and **Health** keeps count. They know nothing about the player, enemies or bosses, so every actor wires them up the same way.

## How it works

1. An attack turns its `Hitbox` on (`set_active(true)`). This enables its collision shapes.
2. A `Hurtbox` whose collision mask includes the hitbox's layer gets `area_entered` and reports it.
3. The hurtbox emits `hurt(hitbox)`, then, if its `health` is set, calls `health.take_damage(hitbox.damage)`.
4. `Health` emits `health_changed(current, maximum)`, and `died` when it reaches 0.
5. The owner listens to these signals and reacts (flash, knockback, respawn...).

The attack turns the hitbox off again after its active window. Turning a hitbox off and on counts as a new contact, so **each activation hits each hurtbox at most once**. A single swing never deals damage twice, however many frames it overlaps.

```
Player                                   TrainingDummy
└── Visual                               ├── Hurtbox ──hurt──► dummy flashes and tilts
    └── AttackHitbox ──area_entered──►   │      └──take_damage──► Health
        (player_attacks layer)           │                         ├─ health_changed ─► health bar
                                         │                         └─ died ─► break, rebuild later
```

### Who detects whom

Only hurtboxes detect (`monitoring = true`, `monitorable = false`). Hitboxes are only detected (`monitoring = false`). Both scripts set this in `_ready()`, so it can't be set wrong in a scene. Detection then runs one way, and only the receiving side decides whether a hit counts (for example during invincibility).

### Layers

| Node | Collision layer | Collision mask |
|---|---|---|
| Player attack `Hitbox` | `player_attacks` (4) | none |
| Enemy attack `Hitbox` | `enemy_attacks` (5) | none |
| Enemy `Hurtbox` | none | `player_attacks` (4) |
| Player `Hurtbox` (planned) | none | `enemy_attacks` (5), `hazards` (6) |

This also prevents actors from hitting themselves: the player's hurtbox will never look at `player_attacks`.

### Facing and knockback

Put an attack's hitbox under the actor's flipped `Visual` node. It moves to the other side with the visuals, and `get_knockback()` mirrors `knockback_direction` when the hitbox is flipped (negative global `scale.x`). Receivers read the knockback from the hitbox they were hit by.

## Player attack

The `Attack` state (`actors/player/states/attack.gd`) runs one swing in three phases:

| Phase | Length | Hitbox |
|---|---|---|
| Startup | `attack_startup` | Off. Wind-up, gives the swing weight |
| Active | `attack_active` | On |
| Recovery | `attack_recovery` | Off. The commitment that makes attacking a decision |

- Attacking is possible from Idle, Run, Jump and Fall.
- Facing is locked for the whole swing.
- On the ground the player slows down with `friction`. In the air, air control and gravity still apply.
- Attack presses are **buffered** for `attack_buffer_time`. Pressing attack during recovery or just before landing starts the next swing as soon as possible.
- `exit()` always turns the hitbox off, so an interrupted swing (a respawn, for example) never leaves it on.

The hitbox placeholder (`Visual/AttackHitbox/Slash`) is a translucent rectangle that is visible only while the hitbox is on.

## Training dummy

`actors/training_dummy/` is a stationary target placed in the test room. It has a `Hurtbox`, a `Health` and a small health bar. When hit it flashes (an over-bright `modulate`, which works because 2D HDR is on) and tilts away from the hit. At 0 health it disappears, then rebuilds with full health after `respawn_delay`.

It has no behaviour of its own, so unlike other actors it has no `states/` folder.

## Files

| File | Role |
|---|---|
| `components/combat/hitbox.gd` | `Hitbox`: damage and knockback, `set_active()` |
| `components/combat/hurtbox.gd` | `Hurtbox`: detects hitboxes, invincibility, emits `hurt` |
| `components/combat/health.gd` | `Health`: hit points, `health_changed` and `died` |
| `actors/player/states/attack.gd` | Player attack state |
| `actors/training_dummy/training_dummy.tscn` | Dummy scene |
| `actors/training_dummy/training_dummy.gd` | Hit reaction, break and rebuild |

## Tuning

### Hitbox

| Value | Default | Effect |
|---|---|---|
| `damage` | 1 | Health removed per hit |
| `knockback_force` | 120 | Knockback strength (px/s) |
| `knockback_direction` | (1, 0) | Direction when facing right, mirrored when flipped |
| `active_on_start` | false | On for hazards that always hurt |

### Hurtbox

| Value | Default | Effect |
|---|---|---|
| `health` | none | `Health` node that takes the damage automatically |
| `invincibility_time` | 0 | Immunity after a hit (s). 0 means every new hit counts |

### Health

| Value | Default | Effect |
|---|---|---|
| `max_health` | 5 | Starting and maximum health |

### Player attack

Set on the `Player` node, group **Attack**.

| Value | Default | Effect |
|---|---|---|
| `attack_startup` | 0.05 | Wind-up before the hitbox turns on (s) |
| `attack_active` | 0.1 | How long the hitbox is on (s) |
| `attack_recovery` | 0.15 | Time after the hitbox turns off before the player can act (s) |
| `attack_buffer_time` | 0.12 | How early an attack press is remembered (s) |

The attack's damage and knockback are set on `Visual/AttackHitbox` in `player.tscn`.

### Training dummy

| Value | Default | Effect |
|---|---|---|
| `respawn_delay` | 1.5 | Seconds before a broken dummy rebuilds |
| `hit_tilt_degrees` | 14 | How far it tilts when hit |
| `hit_flash_time` | 0.12 | How long the white flash lasts (s) |

Its health is set on its `Health` child node.

## Extending

**A new damageable actor:** add a `Health` node and a `Hurtbox` (an `Area2D` with the `Hurtbox` script and a `CollisionShape2D`). Set the hurtbox's mask to the attack layer that should hurt it, point its `health` at the `Health` node, and connect `hurt` and `died` in the actor's root script.

**A new attack:** add a `Hitbox` (an `Area2D` with the `Hitbox` script and a shape) under the actor's `Visual` node, on its attack layer. Add a state that calls `set_active(true)` and `set_active(false)` at the right times, and `set_active(false)` in `exit()`.

**A hazard (spikes):** a `Hitbox` on the `hazards` layer with `active_on_start` enabled.

## Known limitations

- The player has no hurtbox or health yet, so nothing can hurt them except the kill zone.
- A hurtbox only reacts to *new* contacts. A hitbox that stays overlapping after invincibility ends doesn't hit again. Contact damage from always-on hazards will need a re-check of overlapping areas when invincibility ends.
- No hit-stop or screen shake yet.
- Single attack only: no combos, no up/down attacks.
- Placeholder rectangles for the slash and the dummy.
