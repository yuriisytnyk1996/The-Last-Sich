# Combat

Three small components in `components/combat/` handle all damage in the game: a **Hitbox** deals it, a **Hurtbox** receives it, and **Health** keeps count. They know nothing about the player, enemies or bosses, so every actor wires them up the same way.

## How it works

1. An attack turns its `Hitbox` on (`set_active(true)`). This enables its collision shapes.
2. A `Hurtbox` whose collision mask includes the hitbox's layer gets `area_entered` and reports it.
3. The hurtbox emits `hurt(hitbox)`, tells the hitbox with `register_hit()` (which emits the hitbox's `hit_landed`), then, if its `health` is set, calls `health.take_damage(hitbox.damage)`.
4. `Health` emits `health_changed(current, maximum)`, and `died` when it reaches 0.
5. The owner listens to these signals and reacts (flash, knockback, respawn...).

The attack turns the hitbox off again after its active window. Turning a hitbox off and on counts as a new contact, so **each activation hits each hurtbox at most once**. A single swing never deals damage twice, however many frames it overlaps.

```
Player                                   TrainingDummy
└── Visual                               ├── Hurtbox ──hurt──► dummy flashes and tilts
    └── Attacks/Side ──area_entered──►   │      ├──register_hit──► Hitbox.has_hit()
        (player_attacks layer)           │      └──take_damage──► Health
                                         │                         ├─ health_changed ─► health bar
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

## Player attacks

The attack direction is read from the vertical input **at the moment attack is pressed**. A stick held diagonally below `attack_vertical_threshold` counts as a side attack.

| Input | On the ground | In the air |
|---|---|---|
| Attack | **SideAttack** | **SideAttack** |
| Up + attack | **UpAttack** | **UpAttack** |
| Down + attack | **CrouchAttack** | **SideAttack** |

Each attack is its own state in `actors/player/states/attacks/` with its own hitbox under `Visual/Attacks`. The swing timing lives in the shared base class `PlayerAttackState`:

| Phase | Length | Hitbox |
|---|---|---|
| Startup | `attack_startup` | Off. Wind-up, gives the swing weight |
| Active | `attack_active` | On |
| Recovery | `attack_recovery` | Off. The commitment that makes attacking a decision |

### Movement during attacks

| Attack | Movement | Facing |
|---|---|---|
| SideAttack, ground | Stops dead | Pushing the other way turns the player around mid-swing; the hitbox turns with them |
| UpAttack, ground | Stops dead | Locked |
| CrouchAttack | Stops dead | Locked |
| SideAttack / UpAttack, air | Full air control | Locked |

Whether the swing counts as a ground or an air swing is decided when it starts. Attacking on the ground is a commitment: you plant your feet to swing. In the air you keep drifting, so air attacks stay useful while jumping over enemies. Gravity always applies. Jumping and dashing aren't possible until the swing ends.

### Re-swing after a miss

If a swing **missed**, pressing attack during its recovery cuts the recovery short and starts the next swing immediately (in whatever direction is held then). A swing that **hit** plays out its full recovery. This keeps whiffing cheap to correct, while landing hits keeps its rhythm. Combos will later chain from hits.

The miss check uses `Hitbox.has_hit()`, which is reset each time the hitbox turns on.

### Other rules

- Attack presses are **buffered** for `attack_buffer_time`. Pressing attack just before a swing or a landing ends still starts the next swing.
- `exit()` always turns the hitbox off, so an interrupted swing (a respawn, for example) never leaves it on.
- Each hitbox has a placeholder `Slash` rectangle that is visible only while the hitbox is on.

### Hitboxes

| Hitbox | Position | Size | Knockback direction |
|---|---|---|---|
| `Visual/Attacks/Side` | (16, -16) | 22×18 | (1, 0) |
| `Visual/Attacks/Up` | (2, -40) | 24×20 | (0, -1) |
| `Visual/Attacks/Crouch` | (16, -6) | 22×10 | (1, 0) |

Positions are relative to the player's feet, facing right.

## Training dummy

`actors/training_dummy/` is a stationary target placed in the test room. It has a `Hurtbox`, a `Health` and a small health bar. When hit it flashes (an over-bright `modulate`, which works because 2D HDR is on) and tilts away from the hit. At 0 health it disappears, then rebuilds with full health after `respawn_delay`.

It has no behaviour of its own, so unlike other actors it has no `states/` folder.

## Files

| File | Role |
|---|---|
| `components/combat/hitbox.gd` | `Hitbox`: damage and knockback, `set_active()`, `has_hit()`, `hit_landed` |
| `components/combat/hurtbox.gd` | `Hurtbox`: detects hitboxes, invincibility, emits `hurt` |
| `components/combat/health.gd` | `Health`: hit points, `health_changed` and `died` |
| `actors/player/states/attacks/player_attack_state.gd` | `PlayerAttackState`: swing phases, re-swing, planted on the ground / air control in the air |
| `actors/player/states/attacks/side_attack.gd` | Side slash, turns around on the ground |
| `actors/player/states/attacks/up_attack.gd` | Up slash |
| `actors/player/states/attacks/crouch_attack.gd` | Low slash (ground only) |
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
| `attack_vertical_threshold` | 0.75 | How far up or down the stick must be held for an up or crouch attack |

All three attacks share the timing. Damage and knockback are set per attack on the hitboxes under `Visual/Attacks` in `player.tscn`.

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

**A new player attack:** add a hitbox under `Visual/Attacks`, a script in `actors/player/states/attacks/` that extends `PlayerAttackState` (override `move()` for different movement), a state node pointing its `hitbox` at the new hitbox, a name constant in `PlayerState`, and a rule in `PlayerState.attack_state()`.

**A hazard (spikes):** a `Hitbox` on the `hazards` layer with `active_on_start` enabled.

## Known limitations

- The player has no hurtbox or health yet, so nothing can hurt them except the kill zone.
- A hurtbox only reacts to *new* contacts. A hitbox that stays overlapping after invincibility ends doesn't hit again. Contact damage from always-on hazards will need a re-check of overlapping areas when invincibility ends.
- No hit-stop or screen shake yet.
- No combos, charged attacks or movement attacks (dash attack, dive attack). These are planned as upgrades once an upgrade system exists.
- No crouch state yet: the crouch attack doesn't lower the player's body, it only swings low.
- All three attacks share one set of timings.
- Placeholder rectangles for the slash and the dummy.
