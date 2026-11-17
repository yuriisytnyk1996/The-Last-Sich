# Enemies

Enemies share one base class (`Enemy`), one damage handler (`EnemyDamage`) and a set of shared states. A specific enemy is a scene that wires these together and adds its own attack. There are five so far:

- **Raider:** a melee grunt that patrols, chases the player and swings a saber.
- **Musketeer:** a ranged enemy that stands its ground, aims and fires a musket ball, then reloads. See [Musketeer](#musketeer).
- **Shieldbearer:** a slow spearman whose shield blocks hits from the front. Break its guard with a heavy hit, or get behind it. See [Shieldbearer](#shieldbearer).
- **Boar:** a charger that runs in a straight line once it sees the player, and crashes into walls. See [Boar](#boar).
- **Crow:** a flying enemy that hovers above the player and swoops down at them. See [Crow](#crow).

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

When the state ends, for any reason, the hitbox turns off and the `cooldown` starts. Subclasses override `move()` to decide how the enemy moves during the attack, and `_on_active()` to act once when the wind-up ends. The raider's `SaberSlash` lunges forward at `lunge_speed` while the blade is out, and never off a ledge. The `hitbox` is optional: the musketeer's `MusketShot` has none and fires a projectile from `_on_active()` instead.

### Projectiles

`EnemyProjectile` (`actors/enemies/attacks/`) is a `Hitbox` that flies. `launch(from, direction)` places it and turns it to face the direction, then it flies in a straight line at `speed`. It vanishes on its first hit (or a [guard slide](/systems/combat#guard-slide), for a HEAVY one), on a wall, after `lifetime`, or on a room change. Its mask is `world` only, so it flies through one-way platforms. It is added next to the enemy that fired it, so it keeps flying if the enemy dies. Projectiles are never `parryable`: the player jumps over them or gets out of the way.

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

Only the raider's `Slash` is parryable so far. Contact damage and projectiles never are.

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

`reset()` sends every enemy back to its spawn point and `start_facing` with full health, patrolling, dead or not. Bosses go back to Dormant instead.

## Musketeer

A ranged enemy that plants itself and makes the player come to it. It uses the shared `Enemy` root script and replaces two shared states with its own: `HoldRange` as its `Chase`, and `MusketShot` as its `Attack`. Patrol, Hurt, Stunned and Dead are shared.

```
Chase (HoldRange) ──can aim, off cooldown, on floor──► Attack (MusketShot)
  can aim: stand
  out of range: walk closer (not off a ledge)
  neither: stand facing the player, give up after give_up_time
```

1. **Closing in.** Out of `attack_range`, on its level and with nothing in the way, it walks closer. It never backs away: a player who reaches it gets an easy kill (40 health, no melee attack, only contact damage).
2. **Can it aim?** `MusketShot.can_aim()`: the player is in `attack_range`, in [sight](#line-of-sight), in front, and within `max_aim_angle` of straight ahead from the `Muzzle`. When it can, it stands and fires whenever it's on the floor and off cooldown, at point-blank range too.
3. **Stuck.** A player it can't aim at and can't walk closer to (right under its ledge, up on a platform, behind cover) leaves it standing and facing them. After `give_up_time` it turns away and patrols, like the shared Chase. It also gives up when the player is further than `lose_range` or out of sight for `lose_sight_time`.
4. **Aiming.** Through the wind-up the aim line (`AimPivot`, the telegraph) follows the player's body, clamped to `max_aim_angle`. For the last `aim_lock` seconds it freezes. Then the ball leaves the `Muzzle` along the line.
5. **Reload.** The long recovery is the opening: close in while it reloads.

A hit during the wind-up interrupts the shot, like any enemy attack. A musketeer on a raised block can't see a player standing close to the foot of the block (the block's edge blocks the sight ray), so it walks to the edge and shoots down.

## Shieldbearer

A slow melee enemy with a shield. It uses the shared `Enemy` root script and the shared states. Its attack node uses `EnemyAttackState` itself (a planted spear thrust with a long reach, parryable), and its `Damage` node is `ShieldDamage`, which extends `EnemyDamage`.

While it patrols, chases or attacks, the shield is up. `ShieldDamage` sets the hurtbox's [guard](/systems/combat#blocking):

| Hit | Result |
|---|---|
| From the front, LIGHT or NORMAL | **Blocked:** no damage, no stagger, the shield flashes. The hit doesn't count as landed: no spirit, no combo chain. Bolts stop on it |
| From the front, HEAVY | **Guard break:** the hit lands, and the enemy is stunned for `stun_time` with its shield down, as after a parry |
| From behind | Lands as on any enemy: damage, stagger, poise |
| Any hit while Hurt or Stunned | Lands: the shield is down |

"From the front" means the hit pushes the enemy backwards (`Hitbox.push_direction()` is the opposite of its facing), so a swing from right behind it that reaches past its middle still counts as from behind.

Ways through: a heavy attack (combo finisher, charged slash, lunge, dive, riposte), a parried thrust (Stunned, then a riposte), or getting behind it. It turns slowly (`turn_delay` 0.5), so jumping over it gives a window to hit its back. A patrolling shieldbearer can't see behind itself, so sneaking up on it works too. Hits from behind stagger it and turn it around, and after `max_staggers` it strikes back.

## Boar

A charger. It uses the shared states with `Charge` as its `Attack`, and has `attack_needs_sight` on: it only charges at a player it can see, so standing behind a wall or a low block stops it.

```
Chase ──in attack_range, sees the player, off cooldown──► Charge
  wind-up (paws the ground) ──► run at charge_speed, can't turn
     ├─ wall ──► crash: bounces back, camera shake, Stunned (stun_time)
     ├─ ledge ──► stops at the edge, recovery
     └─ active runs out ──► skid to a stop (recovery)
```

1. **Wind-up.** It faces the player, stands and shows its telegraph. A hit here interrupts it.
2. **Charge.** It runs ahead for up to `active` seconds, with a HEAVY, unparryable `Gore` hitbox. It doesn't follow the player: jump over it, step onto something, or catch it on the guard for a [guard slide](/systems/combat#guard-slide).
3. **Wall.** It crashes, bounces back at `crash_bounce` and is dazed for `stun_time` (the Stunned state), the best opening.
4. **Ledge.** It stops dead at the edge and never runs off. A skid in recovery stops at ledges too.
5. **Recovery.** A skid with low friction, then the cooldown.

It has heavy poise: `max_staggers` 2 and short knockback. After two staggers it charges back at once if the player is within its long `attack_range`.

## Crow

A flying enemy. It has its own root script, `Crow` (extends `Enemy`), and its own Patrol (`Hover`), Chase (`Pursue`) and Attack (`Swoop`). Hurt, Stunned and Dead are shared.

- **No gravity while alive.** `Crow.apply_gravity()` only eases its vertical speed to 0. Dead, it falls to the ground like any body.
- **Collision:** mask `world` only, so it flies through one-way platforms. Walls, floors and solid ceilings stop it.
- **No ledges:** it has no `FloorProbe`. `is_path_blocked()` only checks walls, `can_reach_target()` is true at any height, and `is_target_in_attack_range()` measures the straight-line distance to the player's body.

```
Hover ──sees the player──► Pursue ──sees the player, in attack_range, off cooldown──► Swoop
  ▲                          │                                                          │
  └── out of sight / range ──┘ ◄──────────────────────── recovery ends ─────────────────┘
```

1. **Hover** flies back and forth up to `patrol_distance` from its spawn point, bobbing by `bob_height`. Past the edge it turns back, so after a chase it flies home. It sees like any enemy (front only, `close_range` behind), with a tall `sight_height`, so it spots players far below.
2. **Pursue** flies to a point `hover_height` above the player's feet and `hover_distance` to the side it is on. It gives up after `lose_sight_time` out of sight: hide under a solid ledge or behind a wall.
3. **Swoop.** Wind-up: it rises slowly and tracks the player, freezing its aim `aim_lock` before the dive. Active: it dives in a straight line at `swoop_speed` with parryable `Talons`, stopping early when it hits terrain. Recovery: it drifts back up, the opening to hit it.

A parried swoop stuns it in the air. It has low health (30) and `max_staggers` 2.

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
├── Stats (EnemyStats)           max_health 60
├── Health                       max from Stats
├── Hurtbox                      14×26, mask player_attacks
├── Contact (Hitbox)             10×22, always on, continuous
├── Damage (EnemyDamage)
├── HurtFeedback                 hit_stop 0.05, shake 0.3
└── StateMachine
    ├── Patrol, Chase, Hurt, Stunned, Dead   shared states
    └── Attack                      SaberSlash
```

The musketeer has the same layout, with these differences:

```
Musketeer (CharacterBody2D, Enemy)
├── Visual
│   ├── AimPivot             (14, -18), rotated to aim, telegraph
│   │   └── AimLine          thin 80 px line
│   ├── Barrel               placeholder rectangle
│   └── Muzzle (Marker2D)    (14, -18), where the ball leaves
│                            (no Attacks node)
├── Stats (EnemyStats)       max_health 40
└── StateMachine
    ├── Chase                HoldRange, shot: Attack
    └── Attack               MusketShot
```

The shieldbearer has the raider's layout with `Visual/Shield` and `Visual/Spark` (placeholders), `Visual/Attacks/Thrust` (28×8 at (24, -16), parryable) instead of `Slash`, a `ShieldDamage` script on `Damage` and the plain `EnemyAttackState` script on `Attack`.

The boar has a low, wide body (24×18), `Visual/Attacks/Gore` (14×14 at (16, -9), 30 damage, HEAVY, 220 knockback, not parryable) and the `Charge` script on `Attack`.

The crow's origin is the middle of its body, not its feet. It has no `FloorProbe`, a 12×10 body on mask `world`, `Visual/Attacks/Talons` (14×10, parryable) and the `Hover`, `Pursue` and `Swoop` scripts on `Patrol`, `Chase` and `Attack`.

`musket_ball.tscn` is an `EnemyProjectile` on `enemy_attacks`, mask `world`, 6×4, 20 damage (scaled by the musketeer's `damage` stat), 120 knockback along its flight.

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
| `actors/enemies/attacks/enemy_projectile.gd` | `EnemyProjectile`: a shot that flies straight and ends on a hit or a wall |
| `actors/enemies/musketeer/musketeer.tscn` | Musketeer scene |
| `actors/enemies/musketeer/musket_ball.tscn` | The musket ball |
| `actors/enemies/musketeer/states/hold_range.gd` | Musketeer's Chase: close in, stand and fire, never back away |
| `actors/enemies/musketeer/states/musket_shot.gd` | `MusketShot`: aim, fire, reload; `can_aim()` |
| `actors/enemies/shieldbearer/shieldbearer.tscn` | Shieldbearer scene |
| `actors/enemies/shieldbearer/shield_damage.gd` | `ShieldDamage`: blocks front hits, guard break on HEAVY hits |
| `actors/enemies/boar/boar.tscn` | Boar scene |
| `actors/enemies/boar/states/charge.gd` | Boar attack: straight charge, wall crash, ledge stop |
| `actors/enemies/crow/crow.tscn` | Crow scene |
| `actors/enemies/crow/crow.gd` | `Crow`: flight helpers, no gravity while alive |
| `actors/enemies/crow/states/hover.gd` | Crow's Patrol: hover around the spawn point |
| `actors/enemies/crow/states/pursue.gd` | Crow's Chase: fly above the player, swoop when in range |
| `actors/enemies/crow/states/swoop.gd` | Crow attack: aimed dive, climbs back up |

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
| `attack_needs_sight` | Off | Only starts an attack while it can see the player, so cover stops it |

### EnemyDamage

| Value | Default | Effect |
|---|---|---|
| `hurt_duration` | 0.25 | Stagger after a NORMAL hit (s) |
| `hurt_knockback` | 110 | Slide-back speed after a NORMAL hit (px/s) |
| `heavy_hurt_duration` | 0.45 | Stagger after a HEAVY hit (s) |
| `heavy_knockback` | 180 | Slide-back speed after a HEAVY hit (px/s) |
| `flinches` | On | Off: NORMAL and HEAVY hits never stagger it (bosses). A parry still stuns |
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

The slash and contact hitboxes use the `Hitbox` defaults: 20 damage, NORMAL reaction. The contact hitbox has the CONTACT element. Health, the damage multiplier and resistances are on the `Stats` node, see [Stats](/systems/stats#enemy-stats). The slash has `parryable` on.

### Musketeer

Set on the musketeer's root node, attack node and ball. Values that differ from the raider:

| Node | Value | Musketeer | Effect |
|---|---|---|---|
| Root | `patrol_speed` | 25 | |
| Root | `chase_speed` | 50 | Speed when closing in |
| Root | `sight_range` | 200 | |
| Root | `sight_height` | 64 | Sees and shoots players up to 4 tiles above or below |
| Root | `lose_range` | 260 | |
| Root | `lose_sight_time` | 2.0 | |
| Root | `attack_range` | 180 | Fires from this far |
| Stats | `max_health` | 40 | |
| Damage | `currency_reward` | 15 | |
| Attack | `startup` | 0.7 | Aiming time (s) |
| Attack | `active` | 0.1 | |
| Attack | `recovery` | 1.2 | Reload, the opening to punish (s) |
| Attack | `cooldown` | 0.8 | |
| Attack | `aim_lock` | 0.2 | The aim freezes this long before the shot (s) |
| Attack | `max_aim_angle` | 35 | Furthest it aims up or down from straight ahead (degrees) |
| Ball | `speed` | 260 | Flight speed (px/s), `EnemyProjectile` default |
| Ball | `lifetime` | 1.5 | Vanishes after this if it hits nothing (s), `EnemyProjectile` default |

### Shieldbearer

| Node | Value | Shieldbearer | Effect |
|---|---|---|---|
| Root | `patrol_speed` | 25 | |
| Root | `chase_speed` | 45 | |
| Root | `turn_delay` | 0.5 | Slow to turn, so a jump over it opens its back |
| Root | `attack_range` | 40 | |
| Stats | `max_health` | 80 | |
| Damage | `stun_time` | 1.4 | Stunned after a guard break or a parried thrust (s) |
| Damage | `currency_reward` | 20 | |
| Damage | `shield` | none | Placeholder shown while the shield is up (`Visual/Shield`) |
| Damage | `spark` | none | Flash shown on a block (`Visual/Spark`) |
| Damage | `spark_time` | 0.08 | How long the block flash stays (s) |
| Attack | `startup` | 0.55 | |
| Attack | `active` | 0.15 | |
| Attack | `recovery` | 0.6 | |
| Attack | `cooldown` | 0.9 | |

### Boar

| Node | Value | Boar | Effect |
|---|---|---|---|
| Root | `patrol_speed` | 30 | |
| Root | `chase_speed` | 55 | |
| Root | `sight_range` | 220 | |
| Root | `lose_range` | 280 | |
| Root | `turn_delay` | 0.5 | |
| Root | `attack_range` | 150 | Charges from this far |
| Root | `attack_needs_sight` | On | No charge at a player behind cover |
| Stats | `max_health` | 90 | |
| Damage | `hurt_knockback` | 50 | |
| Damage | `heavy_knockback` | 90 | |
| Damage | `max_staggers` | 2 | |
| Damage | `stun_time` | 1.6 | Dazed after crashing into a wall (s) |
| Damage | `currency_reward` | 20 | |
| Attack | `startup` | 0.7 | Pawing the ground (s) |
| Attack | `active` | 1.0 | Longest charge (s) |
| Attack | `recovery` | 0.6 | The skid (s) |
| Attack | `cooldown` | 1.2 | |
| Attack | `charge_speed` | 220 | Charge speed (px/s) |
| Attack | `charge_acceleration` | 900 | How fast it reaches charge speed (px/s²) |
| Attack | `crash_bounce` | 90 | Bounce-back speed off a wall (px/s) |
| Attack | `crash_shake` | 0.35 | Camera shake on a crash |
| Attack | `skid_friction` | 350 | Friction in the skid (px/s²) |

### Crow

| Node | Value | Crow | Effect |
|---|---|---|---|
| Root | `patrol_speed` | 35 | Hover speed (px/s) |
| Root | `chase_speed` | 75 | Pursuit speed (px/s) |
| Root | `acceleration` | 400 | Steering (px/s²) |
| Root | `friction` | 500 | Also how fast vertical drift stops (px/s²) |
| Root | `sight_range` | 160 | |
| Root | `sight_height` | 160 | Sees the player far below |
| Root | `close_range` | 32 | |
| Root | `lose_range` | 260 | |
| Root | `turn_dead_zone` | 8 | |
| Root | `attack_range` | 110 | Straight-line distance to the player's body (px) |
| Root | `patrol_distance` | 64 | Hover range left and right of the spawn point (px) |
| Root | `bob_height` | 6 | Up-and-down bob while hovering (px) |
| Root | `bob_speed` | 1.2 | Bob cycles per second |
| Root | `hover_height` | 56 | Height above the player's feet while pursuing (px) |
| Root | `hover_distance` | 40 | Distance to the side of the player while pursuing (px) |
| Stats | `max_health` | 30 | |
| Damage | `hurt_knockback` | 120 | |
| Damage | `max_staggers` | 2 | |
| Damage | `currency_reward` | 8 | |
| Attack | `startup` | 0.55 | |
| Attack | `active` | 0.4 | Longest dive (s) |
| Attack | `recovery` | 0.7 | |
| Attack | `cooldown` | 1.0 | |
| Attack | `swoop_speed` | 230 | Dive speed (px/s) |
| Attack | `aim_lock` | 0.15 | The aim freezes this long before the dive (s) |
| Attack | `rise_speed` | 25 | Upward drift in the wind-up and recovery (px/s) |

The `Stunned` state node has an optional `mark` (a `CanvasItem` shown while stunned).

## Extending

**A new enemy:** create `actors/enemies/<name>/<name>.tscn` with the same nodes as the raider (the easiest start is to duplicate `raider.tscn`). Keep the shared states and replace the `Attack` node's script with its own `EnemyAttackState` subclass in `actors/enemies/<name>/states/`. Tune it on the root node, the attack node and its `Health`.

**A different attack movement:** override `move(delta)` in the attack subclass. Read `_phase` to move differently per phase.

**A ranged attack:** extend `EnemyAttackState`, leave `hitbox` empty and spawn an `EnemyProjectile` scene in `_on_active()`, as `MusketShot` does.

**A new behaviour:** add a state script in the enemy's own `states/` folder and a node for it under `StateMachine`, as the crow does. If two enemies need it, move it up to `actors/enemies/states/`. If the enemy needs extra data or helpers, give it a root script that extends `Enemy`.

**An enemy that ignores staggers:** turn off `flinches` on its `Damage` node, or override `can_be_staggered()` in its states.

**Where it goes after a hit or an attack:** `Enemy.alert_state()` (Chase or Patrol) and `Enemy.home_state()` (where `reset()` sends it, Patrol) can be overridden in a root script. Bosses use them to stay in the fight, see [Bosses](/systems/bosses).

**Faster attacks:** override `time_scale()` in an `EnemyAttackState` subclass; it multiplies startup, active and recovery. `BossAttack` uses it for phases.

## Known limitations

- Sight is a single ray to the player's mid-body. A player whose head pokes over a wall, with the middle of the body hidden, isn't seen.
- A chasing enemy doesn't search for the player: when sight is lost it keeps running at the player's position until `lose_sight_time` runs out.
- Ground enemies don't jump, drop down or climb. A player standing on a step or ledge they can't reach is safe from melee, but not from a musketeer or a crow.
- The crow flies straight at its pursuit point with no pathfinding. A wall between it and the player stops it until it loses sight and flies home.
- A wall right in front of the `FloorProbe` reads as a ledge (the ray starts inside the tile), so a boar standing against a wall stops instead of crashing.
- A boar charge that runs into the shieldbearer or another enemy passes through it: enemies don't collide with each other.
- The musket ball flies straight, aimed at where the player was when the aim froze. It doesn't lead a moving target.
- Several enemies overlap freely because enemy bodies don't collide with each other.
- One attack per enemy. Bosses pick between several (see [Bosses](/systems/bosses)); regular enemies don't yet.
- Placeholder rectangles for the bodies, the glint, the slash, the barrel, the aim line, the ball, the shield and the new hitboxes. No animations.
