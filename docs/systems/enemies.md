# Enemies

Enemies share one base class (`Enemy`), one damage handler (`EnemyDamage`) and a set of shared states. A specific enemy is a scene that wires these together and adds its own attack. The first enemy is the **raider**: a melee grunt that patrols, chases the player and swings a saber.

## How it works

```
Patrol ──sees player──► Chase ──in range, off cooldown, on floor──► Attack
  ▲                       │  ▲                                        │
  └──── player lost ──────┘  └────────── recovery ends ───────────────┘

any state ──NORMAL / HEAVY hit (if staggerable)──► Hurt ──► Chase or Patrol
any state ──health 0──► Dead ──Enemy.reset()──► Patrol
```

1. **Patrol** walks at `patrol_speed`. At a wall or a ledge it stops, waits `turn_pause` and turns around. Enemies never walk off ledges: a `FloorProbe` raycast under `Visual` checks for ground just ahead.
2. When the player is in front, within `sight_range` horizontally and `sight_height` vertically, the enemy switches to **Chase**. It can't see behind itself, so the player can sneak up on a patrolling enemy.
3. **Chase** runs at `chase_speed` towards the player, still stopping at walls and ledges. It turns only once the player is more than `turn_dead_zone` to one side, so it doesn't jitter when the player is right above it. It gives up and patrols again once the player is further than `lose_range`.
4. Within `attack_range` (and at the same height), with the cooldown over and on the floor, it starts its **Attack**.
5. A hit sends it to **Hurt** (see [Hit reactions](#hit-reactions)). Afterwards it goes back to Chase if the player is still close, or Patrol otherwise.
6. At 0 health it enters **Dead**: hurtbox and contact damage turn off, the body darkens, slides to a stop and fades out after `corpse_time`.

### Attacks

Enemy attacks extend `EnemyAttackState`, which runs the same three phases as player attacks, with timings sized for the player to react to:

| Phase | Length | What happens |
|---|---|---|
| Startup | `startup` | The `telegraph` node is shown (the raider's yellow glint above its head). A hit here interrupts the attack |
| Active | `active` | The hitbox is on. The attack is committed: hits still deal damage but no longer stagger |
| Recovery | `recovery` | The opening to punish |

When the state ends, for any reason, the hitbox turns off and the `cooldown` starts. Subclasses override `move()` to decide how the enemy moves during the attack. The raider's `SaberSlash` lunges forward at `lunge_speed` while the blade is out, and never off a ledge.

### Contact damage

Each enemy has a `Contact` hitbox around its body: always on, `continuous`, on `enemy_attacks`. Touching an enemy hurts. It pushes straight up with no force, so the player is knocked away from the enemy's centre (see `Hitbox.push_direction()`). Enemy bodies are on the `enemies` layer and nothing collides with it, so the player passes through enemies instead of standing on them.

### Hit reactions

`EnemyDamage` reads the hitbox's `reaction`:

| Reaction | Enemy |
|---|---|
| `LIGHT` | Damage and flash only |
| `NORMAL` | Turns to face the hit, **Hurt** for `hurt_duration`, slides back at `hurt_knockback` |
| `HEAVY` | Same with `heavy_hurt_duration` and `heavy_knockback` |

A state can refuse the stagger by overriding `EnemyState.can_be_staggered()`. Attacks do this once their hitbox is out, and Dead always does.

### Finding the player

Enemies find the player through the `player` group and know whether it is alive from `Events.player_health_changed`. Nothing in `actors/enemies/` references the `Player` class, so enemies stay independent of the player's code.

### Respawning

Enemies join the `enemies` group. When the player respawns, the room calls `reset()` on the whole group: every enemy goes back to its spawn point and `start_facing` with full health and patrols again, dead or not. Pits (the room's `KillZone`) kill enemies the same way they kill the player.

## Scene layout

```
Raider (CharacterBody2D, Enemy)  layer: enemies, mask: world
├── CollisionShape2D             14×28
├── Visual                       flipped with facing
│   ├── Body, Eye                placeholder rectangles
│   ├── Telegraph                glint shown during the wind-up
│   ├── FloorProbe (RayCast2D)   (10, -4) → 12 px down, ledge check
│   └── Attacks/Slash (Hitbox)   (18, -14), 24×16, layer enemy_attacks
├── Health                       max_health 3
├── Hurtbox                      14×26, mask player_attacks
├── Contact (Hitbox)             10×22, always on, continuous
├── Damage (EnemyDamage)
├── HurtFeedback                 hit_stop 0.05, shake 0.3
└── StateMachine
    ├── Patrol, Chase, Hurt, Dead   shared states
    └── Attack                      SaberSlash
```

## Files

| File | Role |
|---|---|
| `actors/enemies/enemy.gd` | `Enemy`: shared tuning, movement and sensing helpers, `reset()` |
| `actors/enemies/enemy_damage.gd` | `EnemyDamage`: hit reactions, hurt and death tuning |
| `actors/enemies/enemy_state.gd` | `EnemyState`: state names, `can_be_staggered()`, `alert_state()` |
| `actors/enemies/states/patrol.gd` | Walk, turn at walls and ledges, spot the player |
| `actors/enemies/states/chase.gd` | Run at the player, start attacks, give up |
| `actors/enemies/states/hurt.gd` | Knockback and stagger |
| `actors/enemies/states/dead.gd` | Combat off, darken and fade |
| `actors/enemies/states/enemy_attack_state.gd` | `EnemyAttackState`: telegraphed startup, active, recovery, cooldown |
| `actors/enemies/raider/raider.tscn` | Raider scene |
| `actors/enemies/raider/states/saber_slash.gd` | Raider attack: forward lunge while the blade is out |

## Tuning

### Enemy

Set on the enemy's root node. Raider values are the defaults.

| Value | Default | Effect |
|---|---|---|
| `start_facing` | Right | Facing at spawn and after a reset. The raider scene faces left |
| `patrol_speed` | 30 | Walking speed while patrolling (px/s) |
| `chase_speed` | 70 | Running speed while chasing (px/s) |
| `acceleration` | 600 | How fast it reaches walking or running speed (px/s²) |
| `friction` | 800 | How fast it stops, also after knockback (px/s²) |
| `gravity` | 900 | Fall acceleration (px/s²) |
| `max_fall_speed` | 360 | Fall speed cap (px/s) |
| `turn_pause` | 0.6 | Wait at a wall or ledge before turning (s) |
| `sight_range` | 140 | How far ahead it notices the player (px) |
| `sight_height` | 40 | How far above or below the player can be to be seen or attacked (px) |
| `lose_range` | 220 | Distance at which a chase is given up (px) |
| `turn_dead_zone` | 4 | How far to one side the player must be before it turns (px) |
| `attack_range` | 30 | Horizontal distance at which an attack starts (px) |

### EnemyDamage

| Value | Default | Effect |
|---|---|---|
| `hurt_duration` | 0.25 | Stagger after a NORMAL hit (s) |
| `hurt_knockback` | 110 | Slide-back speed after a NORMAL hit (px/s) |
| `heavy_hurt_duration` | 0.45 | Stagger after a HEAVY hit (s) |
| `heavy_knockback` | 180 | Slide-back speed after a HEAVY hit (px/s) |
| `corpse_time` | 0.5 | How long the body stays before fading (s) |
| `fade_time` | 0.4 | Fade-out length (s) |

### EnemyAttackState

Set on the attack state node.

| Value | Default | Effect |
|---|---|---|
| `hitbox` | none | Hitbox turned on during the active window |
| `telegraph` | none | Node shown during the wind-up |
| `startup` | 0.45 | Wind-up before the hitbox turns on (s) |
| `active` | 0.12 | How long the hitbox is on (s) |
| `recovery` | 0.5 | Time after the hitbox turns off (s) |
| `cooldown` | 0.6 | Time after the attack before the next one (s) |
| `lunge_speed` | 120 | `SaberSlash` only: forward speed while the blade is out (px/s) |

The slash and contact hitboxes use the `Hitbox` defaults: 1 damage, NORMAL reaction.

## Extending

**A new enemy:** create `actors/enemies/<name>/<name>.tscn` with the same nodes as the raider (the easiest start is to duplicate `raider.tscn`). Keep the shared states and replace the `Attack` node's script with its own `EnemyAttackState` subclass in `actors/enemies/<name>/states/`. Tune it on the root node, the attack node and its `Health`.

**A different attack movement:** override `move(delta)` in the attack subclass. Read `_phase` to move differently per phase.

**A new behaviour (ranged attack, flying, guarding):** add a state script in the enemy's own `states/` folder and a node for it under `StateMachine`. If two enemies need it, move it up to `actors/enemies/states/`. If the enemy needs extra data or helpers, give it a root script that extends `Enemy`.

**An enemy that ignores staggers:** override `can_be_staggered()` in its states.

## Known limitations

- An enemy can be hit again during its startup each time it recovers, so a player who keeps swinging can keep a lone enemy staggered. A poise or stagger limit is planned.
- Sight is distance only: enemies see through walls and platforms.
- Enemies don't jump, drop down or climb. A player standing on a step or ledge they can't reach is safe from melee.
- Several enemies overlap freely because enemy bodies don't collide with each other.
- One attack per enemy. Enemies with several attacks will need a state that picks between them.
- Placeholder rectangles for the body, the glint and the slash. No animations.
