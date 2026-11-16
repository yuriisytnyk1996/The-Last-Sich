# Enemies

Enemies share one base class (`Enemy`), one damage handler (`EnemyDamage`) and a set of shared states. A specific enemy is a scene that wires these together and adds its own attack. The first enemy is the **raider**: a melee grunt that patrols, chases the player and swings a saber.

## How it works

```
Patrol ──sees player──► Chase ──in range, off cooldown, on floor──► Attack
  ▲                       │  ▲                                        │
  └──── player lost ──────┘  └────────── recovery ends ───────────────┘

any state ──NORMAL / HEAVY hit (if staggerable)──► Hurt ──► Chase or Patrol
Attack ──swing parried──► Stunned ──► Chase or Patrol
any state ──health 0──► Dead ──Enemy.reset()──► Patrol
```

1. **Patrol** walks at `patrol_speed`. At a wall or a ledge it stops, waits `turn_pause` and turns around. Enemies never walk off ledges: a `FloorProbe` raycast under `Visual` checks for ground just ahead.
2. When it [sees](#line-of-sight) the player, the enemy switches to **Chase**. It can't see behind itself, so the player can sneak up on a patrolling enemy, but not closer than `close_range`.
3. **Chase** runs at `chase_speed` towards the player, still stopping at walls and ledges. It turns only once the player is more than `turn_dead_zone` to one side, and at most once per `turn_delay`, so it doesn't flip back and forth when the player runs right under or over it. It gives up and patrols again once the player is further than `lose_range`, or has been out of sight for `lose_sight_time` in a row.
   - **Out of reach:** a player more than `sight_height` above or below (on a platform overhead, or down below a ledge) can't be reached (`Enemy.can_reach_target()`), so the enemy doesn't run at them: it stops and keeps facing them. The same goes for a wall or a ledge in the way.
   - **Giving up:** after `give_up_time` stuck like that, the enemy turns its back and patrols again. It can't see behind itself, so it walks off until the next turn brings the player back into view. Waiting in attack range for the cooldown doesn't count as stuck.
4. Within `attack_range` (and at the same height), with the cooldown over and on the floor, it starts its **Attack**.
5. A hit sends it to **Hurt** (see [Hit reactions](#hit-reactions)). Afterwards it goes back to Chase if the player is still close, or Patrol otherwise.
6. At 0 health it enters **Dead**: hurtbox and contact damage turn off, the body darkens, slides to a stop and fades out after `corpse_time`.

### Line of sight

`Enemy.can_see_target()` runs these checks in order, cheapest first:

1. The player is alive, within `sight_range` horizontally and `sight_height` vertically (measured feet to feet).
2. The player is in front, or within `close_range` in any direction. A player standing right behind an enemy gets noticed.
3. Nothing solid is in between. `SightRay`, a `RayCast2D` at the enemy's eye under `Visual`, is aimed at a point `target_height` above the player's feet and cast on demand (`force_raycast_update()`, the ray is otherwise disabled). Its mask is `world` only, so walls, floors and ceilings block sight, while one-way `platforms` don't: the player is seen through planks.

Losing sight doesn't end a chase right away. Chase counts the time since it last saw the player and gives up after `lose_sight_time`. Ducking behind a pillar or jumping over the enemy's head for a moment keeps it chasing, while hiding behind a wall shakes it off. A chasing enemy always runs at the player's current position: it doesn't remember where it last saw them.

To see the rays while playing, turn on **Debug ▸ Visible Collision Shapes** in the editor.

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

### Poise

Without a limit, a player who keeps swinging could keep a lone enemy staggered forever: every recovery would end in the next hit. `EnemyDamage` counts staggers in a row:

1. Each NORMAL or HEAVY hit that staggers the enemy adds one. After `max_staggers` (3) the enemy's **poise is broken**.
2. While poise is broken, hits still deal damage and flash, but don't stagger. The enemy turns to face the attacker and, if the player is within `attack_range`, attacks right away, even during its cooldown. That attack's wind-up can't be interrupted either (`EnemyAttackState.can_be_staggered()` checks `is_poise_broken()`).
3. The count goes back to 0 when an attack finishes its recovery, or after `poise_recovery` seconds without being hit. `reset()` also restores it.

So the player gets a few free hits, then has to dodge the counterattack.

### Stun

An attack whose hitbox is `parryable` can be [parried](/systems/combat#parry-and-riposte). `EnemyAttackState` connects to its hitbox's `parried` signal and calls `EnemyDamage.stun(hurtbox)`:

1. The enemy is pushed away from the player at `stun_knockback` and enters **Stunned**. Leaving the attack turns its hitbox and telegraph off, as an interrupted attack always does.
2. It stands helpless for `stun_time`, with a placeholder `StunMark` above its head. Poise is restored, so any hit staggers it, and the player's riposte lands in full.
3. Afterwards it goes back to Chase or Patrol, like after Hurt.

Only the raider's `Slash` is parryable so far. Contact damage never is.

### Finding the player

Enemies find the player through the `player` group and know whether it is alive from `Events.player_health_changed`. Nothing in `actors/enemies/` references the `Player` class, so enemies stay independent of the player's code.

### Respawning

Enemies join the `enemies` group. Pits (the room's `KillZone`) kill enemies the same way they kill the player.

**A killed enemy stays dead** until the player rests or dies, even if the player leaves its room and comes back. Enemies left alive come back fresh when their room loads again: at their spawn point, with full health.

| Event | Enemies |
|---|---|
| Leave a room and come back | Killed ones stay dead. Living ones start fresh, because the room is loaded again |
| Player dies, no rest point used | All come back: the current room calls `reset()` on its enemies, and every other room's are back when it loads |
| Player dies after resting | All come back: the rest point's room is reloaded, and every other room's are back when it loads |
| Player rests | All come back: the rest point calls `reset()` on the room's enemies, and every other room's are back when it loads |
| Continue or New game | All come back. Killed enemies are never saved, and the game only saves at rest points, where everyone comes back anyway |

`KilledEnemies` (`levels/killed_enemies.gd`) does the remembering. `World` owns one and calls `watch(room)` after loading each room. It listens to each enemy's `Health.died` and stores the enemy's room scene path and node path. When that room loads again, the enemy's `EnemyDamage.lie_dead()` kills it at once with no fade, so it is in **Dead** like any killed enemy, and the usual `Enemy.reset()` brings it back. `World` calls `KilledEnemies.clear()` when the player rests or dies.

An enemy with `stays_dead` off comes back every time its room loads. Use it for enemies that should always be there, such as weak fodder near a rest point.

`reset()` sends every enemy back to its spawn point and `start_facing` with full health, patrolling, dead or not.

## Scene layout

```
Raider (CharacterBody2D, Enemy)  layer: enemies, mask: world, platforms
├── CollisionShape2D             14×28
├── Visual                       flipped with facing
│   ├── Body, Eye                placeholder rectangles
│   ├── Telegraph                glint shown during the wind-up
│   ├── StunMark                 placeholder bar above the head while stunned
│   ├── FloorProbe (RayCast2D)   (10, -4) → 12 px down, ledge check, mask: world, platforms
│   ├── SightRay (RayCast2D)     (4, -22) at the eye, line of sight, mask: world
│   └── Attacks/Slash (Hitbox)   (18, -14), 24×16, layer enemy_attacks, parryable
├── Health                       max_health 3
├── Hurtbox                      14×26, mask player_attacks
├── Contact (Hitbox)             10×22, always on, continuous
├── Damage (EnemyDamage)
├── HurtFeedback                 hit_stop 0.05, shake 0.3
└── StateMachine
    ├── Patrol, Chase, Hurt, Stunned, Dead   shared states
    └── Attack                      SaberSlash
```

## Files

| File | Role |
|---|---|
| `actors/enemies/enemy.gd` | `Enemy`: shared tuning, movement and sensing helpers, `reset()` |
| `actors/enemies/enemy_damage.gd` | `EnemyDamage`: hit reactions, hurt and death tuning, `lie_dead()` |
| `levels/killed_enemies.gd` | `KilledEnemies`: which enemies stay dead until the player rests or dies |
| `actors/enemies/enemy_state.gd` | `EnemyState`: state names, `can_be_staggered()`, `alert_state()` |
| `actors/enemies/states/patrol.gd` | Walk, turn at walls and ledges, spot the player |
| `actors/enemies/states/chase.gd` | Run at the player, start attacks, give up when out of range or out of sight |
| `actors/enemies/states/hurt.gd` | Knockback and stagger |
| `actors/enemies/states/stunned.gd` | Pushed back and helpless after a parried attack |
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
| `close_range` | 24 | Within this distance the player is noticed behind the enemy too (px) |
| `target_height` | 15 | Height above the player's feet the sight ray aims at, about mid-body (px) |
| `lose_range` | 220 | Distance at which a chase is given up (px) |
| `lose_sight_time` | 1.5 | Time out of sight after which a chase is given up (s) |
| `give_up_time` | 1.0 | Time a chase can't reach the player before the enemy turns away and patrols (s) |
| `turn_dead_zone` | 12 | How far to one side the player must be before it turns (px) |
| `turn_delay` | 0.3 | Time after turning towards the player before it can turn again (s) |
| `attack_range` | 30 | Horizontal distance at which an attack starts (px) |

### EnemyDamage

| Value | Default | Effect |
|---|---|---|
| `hurt_duration` | 0.25 | Stagger after a NORMAL hit (s) |
| `hurt_knockback` | 110 | Slide-back speed after a NORMAL hit (px/s) |
| `heavy_hurt_duration` | 0.45 | Stagger after a HEAVY hit (s) |
| `heavy_knockback` | 180 | Slide-back speed after a HEAVY hit (px/s) |
| `max_staggers` | 3 | Staggers in a row before poise breaks. 0: never staggered |
| `poise_recovery` | 1.5 | Time without being hit before the stagger count resets (s) |
| `stun_time` | 1.0 | How long the enemy stays stunned after a parried attack (s) |
| `stun_knockback` | 100 | Push-back speed when parried (px/s) |
| `corpse_time` | 0.5 | How long the body stays before fading (s) |
| `fade_time` | 0.4 | Fade-out length (s) |
| `stays_dead` | On | Killed, it stays dead across room changes until the player rests or dies. Off: back every time its room loads |
| `currency_reward` | 10 | Currency the player earns for the kill (not again when laid dead on room load). See [Currency](/systems/currency) |

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

The slash and contact hitboxes use the `Hitbox` defaults: 1 damage, NORMAL reaction. The slash has `parryable` on.

The `Stunned` state node has an optional `mark` (a `CanvasItem` shown while stunned).

## Extending

**A new enemy:** create `actors/enemies/<name>/<name>.tscn` with the same nodes as the raider (the easiest start is to duplicate `raider.tscn`). Keep the shared states and replace the `Attack` node's script with its own `EnemyAttackState` subclass in `actors/enemies/<name>/states/`. Tune it on the root node, the attack node and its `Health`.

**A different attack movement:** override `move(delta)` in the attack subclass. Read `_phase` to move differently per phase.

**A new behaviour (ranged attack, flying, guarding):** add a state script in the enemy's own `states/` folder and a node for it under `StateMachine`. If two enemies need it, move it up to `actors/enemies/states/`. If the enemy needs extra data or helpers, give it a root script that extends `Enemy`.

**An enemy that ignores staggers:** set `max_staggers` to 0 on its `Damage` node, or override `can_be_staggered()` in its states.

## Known limitations

- Sight is a single ray to the player's mid-body. A player whose head pokes over a wall, with the middle of the body hidden, isn't seen.
- A chasing enemy doesn't search for the player: when sight is lost it keeps running at the player's position until `lose_sight_time` runs out.
- Enemies don't jump, drop down or climb. A player standing on a step or ledge they can't reach is safe from melee.
- Several enemies overlap freely because enemy bodies don't collide with each other.
- One attack per enemy. Enemies with several attacks will need a state that picks between them.
- Placeholder rectangles for the body, the glint and the slash. No animations.
