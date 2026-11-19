# Bosses

Bosses are enemies built for a one-on-one fight in a closed arena: several attacks picked by distance, phases that start at health thresholds, a boss bar in the HUD, and a win that is saved for good. They reuse the [Enemies](/systems/enemies) base (`Enemy`, `EnemyDamage`, `EnemyAttackState`) and add a `Boss` class, a few shared states and the `BossArena` room object. The first boss is the **Otaman**.

## How it works

```
Dormant ──arena trigger──► Roar ──► Decide ──picks a usable attack──► <Attack>
                            ▲          ▲                                 │
                            │          └──────── recovery ends ──────────┤
                            └──── new phase waiting ─────────────────────┘
<Attack> ──last swing parried──► Stunned ──► Decide (or Roar)
any state ──health 0──► Dead ──► the arena frees it after the fade
```

1. **Dormant** (`actors/bosses/states/dormant.gd`): the boss stands still with its hurtbox and contact damage off, so it can't be worn down before the fight. It is also its `home_state()`: `Enemy.reset()` sends a boss back here, not to Patrol.
2. **The arena:** `BossArena` (`levels/objects/boss_arena.gd`) has a `Trigger` area. When the player walks in, it closes every `Gate` under its `Gates` node, plays its `intro` [cutscene](#intros) if it has one, calls `Boss.awaken()` and sends `Events.boss_fight_started(name, current, maximum)`, which shows the [boss bar](#boss-bar).
3. **Roar** (`roar.gd`): a pause of `duration` with a camera shake and `mark` shown. The boss can't be hurt during it. It plays at the start of the fight and at every new phase.
4. **Decide** (`decide.gd`): faces the player and walks towards them (down to `keep_distance`). After `think_time`, on the floor and off cooldown, it picks an attack at random, weighted by `weight`, from the `BossAttack` states whose `can_use()` is true: allowed in this phase, with the player between `min_range` and `max_range`.
5. **The attack** runs the usual wind-up, active and recovery windows of `EnemyAttackState`, scaled by the phase (`Boss.time_scale()`). When it ends, `Boss.alert_state()` sends the boss back to Decide, or to Roar if a new phase is waiting.
6. **Death:** the shared Dead state darkens and fades the body. The arena opens the gates, freezes the game for `death_hit_stop`, shakes the camera, gives its `item`, sends `Events.boss_fight_ended` and frees the boss once the fade is over. The boss's `currency_reward` is paid as for any enemy.

### Hits, parries and stuns

Bosses don't flinch: their `Damage` node has `flinches` off, so NORMAL and HEAVY hits only flash. A parried swing (a hitbox with `parryable` on) still stuns the boss through the shared Stunned state, which is the opening for a riposte. Leave poise alone (`max_staggers`): with `flinches` off it is never used.

### Phases

`Boss.phase_thresholds` lists health fractions, highest first. With `[0.5]` the second phase starts at half health. Crossing a threshold doesn't interrupt anything: the new phase waits until the current attack or stun ends, then the boss roars and moves on. In the new phase:

- `Boss.phase` goes up and `phase_changed(phase)` is sent.
- Attack timings (startup, active, recovery and Decide's `think_time`) are multiplied by `phase_time_scales[phase]`, so `0.8` is 20% faster.
- Each `BossAttack` has `phases` flags: an attack with only "Phase 2" set is new in the second phase.

### Losing and winning

| Event | Arena and boss |
|---|---|
| Player dies, no rest point used | The arena opens its gates and hides the bar. The room resets its enemies, so the boss goes back to Dormant at full health |
| Player dies after resting | The same, then the rest point's room is reloaded: a fresh, sleeping boss |
| Player leaves and comes back (gates open, boss alive) | The room loads fresh: sleeping boss, open gates |
| Boss killed | `defeated` is saved with the room. From then on the room loads with the boss freed and the gates open, and resting never brings it back (it leaves the `enemies` group as it dies) |

When the boss dies, the arena emits `boss_beaten` (never when a save restores the arena as won), so a [`StoryTrigger`](/systems/story) can mark the boss as beaten: the test arena sets `otaman_beaten`.

While a fight is on, the arena is in the `BossArena.FIGHT_GROUP` group (`boss_fights`), so other systems can tell: the [Duma of the Road Home](/systems/dumas#dumas) can't be sung during a fight.

The arena's gates are taken out of the `persistent` group: the arena alone decides whether they are open, so a fight that ended in death can't leave them shut in the save.

### Intros

`BossArena.intro` is an optional [cutscene](/systems/cutscenes) placed next to the arena. It plays once the gates have shut and before the boss wakes: usually a camera glide to the boss, a shake and its name on a title card. The boss is frozen and the player can't be hurt meanwhile; the boss bar shows only after it, when the fight starts. With a `flag` the intro plays once, so after a death the next attempt goes straight into the fight. The test arena's Otaman has one (`otaman_intro_seen`).

### Boss bar

`BossBar` (`ui/hud/boss_bar.gd`) sits at the bottom centre of the HUD: the boss's `display_name` and a fixed-width bar. It works like the player's [health bar](/systems/hud): damage drops the fill at once and a pale loss segment drains after it. It shows on `Events.boss_fight_started`, follows `Events.boss_health_changed` (sent by `Boss` while awake) and hides `hide_delay` after `Events.boss_fight_ended`. If the player dies it hides at once: the death transition and any tip card pause the game, which would freeze the delay and leave the bar on screen.

## The Otaman

A Cossack war-chief with a sabre and a pistol: 600 health, two phases split at half health. Phase 2 is 20% faster and adds the pistol.

| Attack | Range (px) | Phases | What it does | How to answer |
|---|---|---|---|---|
| `SaberCombo` | 0 to 50 | 1, 2 | Three swings stepping forward, turning to the player before each. Only the last, heavy swing can be parried | Guard or back off from the first two, parry the third for a riposte |
| `LeapSlam` | 70 to 260 | 1, 2 | Crouches, leaps to where the player stands (up to 220 px), slams down and sends a low shockwave along the floor each way | Move out from under it, or guard the slam for a guard slide, then jump the shockwave |
| `DashCut` | 60 to 200 | 1, 2 | Draws back, then dashes along the floor with the blade low. Can't be parried | Jump over it, or guard it for a guard slide |
| `PistolVolley` | 90 to 400 | 2 | Three pistol shots, each aimed at the player afresh, then a long reload. Can't be parried | Keep moving, punish the reload |

The combo is the most likely pick up close (`weight` 3). From further away it leaps or dashes, and in phase 2 it can also shoot.

## Files

| File | Role |
|---|---|
| `actors/bosses/boss.gd` | `Boss`: phases, timing scale, awaken, health to the boss bar |
| `actors/bosses/states/boss_state.gd` | `BossState`: base for the shared boss states, state names |
| `actors/bosses/states/boss_attack.gd` | `BossAttack`: an attack with phases, weight and range |
| `actors/bosses/states/dormant.gd` | Waits for the fight, can't hurt or be hurt |
| `actors/bosses/states/roar.gd` | Invulnerable pause at the start and at each new phase |
| `actors/bosses/states/decide.gd` | Walks in and picks the next attack |
| `actors/bosses/otaman/otaman.tscn` | The Otaman |
| `actors/bosses/otaman/states/` | `saber_combo.gd`, `leap_slam.gd`, `dash_cut.gd`, `pistol_volley.gd` |
| `actors/bosses/otaman/shockwave.tscn`, `pistol_ball.tscn` | Its projectiles (`EnemyProjectile`) |
| `levels/objects/boss_arena.gd`, `boss_arena.tscn` | Runs the fight: trigger, gates, reward, saved win |
| `ui/hud/boss_bar.gd` | Boss name and health bar |
| `levels/rooms/test_arena.tscn` | Test arena behind the test barracks' east door, with the Otaman's intro cutscene |

## Tuning

### Boss

On the boss's root node, along with the usual [Enemy](/systems/enemies#enemy) values.

| Value | Default | Otaman | Effect |
|---|---|---|---|
| `display_name` | "Boss" | "The Otaman" | Name on the boss bar |
| `phase_thresholds` | [0.5] | [0.5] | Health fractions where the next phase starts, highest first |
| `phase_time_scales` | [1.0, 0.8] | [1.0, 0.8] | Attack timing multiplier per phase |

The Otaman also sets `chase_speed` 60, `sight_range` 600, `sight_height` 200, `lose_range` 900 and `turn_delay` 0.2, so it keeps track of the player anywhere in the arena. Its `Stats` has `max_health` 600. Its `Damage` has `flinches` off, `stays_dead` off, `stun_time` 1.4, `corpse_time` 1.2, `fade_time` 1.0 and `currency_reward` 400.

### Shared states

| Value | Default | Effect |
|---|---|---|
| `Roar.duration` | 1.0 | Length of the roar, invulnerable (s) |
| `Roar.shake` | 0.5 | Camera trauma when it starts |
| `Decide.think_time` | 0.4 | Pause before picking an attack (s, scaled by phase) |
| `Decide.keep_distance` | 40 | Stops walking this close to the player (px) |
| `BossAttack.phases` | all | Phases the attack is used in |
| `BossAttack.weight` | 1.0 | Relative chance among usable attacks |
| `BossAttack.min_range` | 0 | Closest the player can be to start it (px) |
| `BossAttack.max_range` | 60 | Furthest the player can be to start it (px) |

### Otaman attacks

| Attack | Startup | Active | Recovery | Cooldown | Other |
|---|---|---|---|---|---|
| `SaberCombo` | 0.5 | 0.1 | 0.7 | 0.3 | `chain_startup` 0.22, `step_speed` 90. Swings deal 15, 15 and 25 (the last HEAVY and parryable) |
| `LeapSlam` | 0.55 | 0.15 | 0.8 | 0.3 | `leap_time` 0.6, `max_leap_distance` 220, `land_shake` 0.5, `wave_offset` (14, -7). Slam 30 HEAVY, shockwave 20 (speed 170) |
| `DashCut` | 0.6 | 0.5 | 0.7 | 0.3 | `dash_speed` 320. 30 HEAVY |
| `PistolVolley` | 0.6 | 0.9 | 1.0 | 0.3 | `shots` 3, `shot_interval` 0.3. Balls deal 15 (speed 220) |

Active is the time the blade is out. For `LeapSlam` it starts on landing, and for `PistolVolley` it should cover all the shots.

### BossArena

| Value | Default | Effect |
|---|---|---|
| `boss` | none | The boss it wakes |
| `intro` | none | [Cutscene](/systems/cutscenes) played before the boss wakes |
| `item` | none | Given when the boss dies |
| `death_shake` | 0.8 | Camera trauma when the boss dies |
| `death_hit_stop` | 0.3 | Freeze on the killing blow (s) |
| `phase_music` | empty | Music per boss phase; see [Audio](/systems/audio#music). Test arena: `boss_1`, `boss_2` |
| `death_sound` | `boss_death` | Sound cue when the boss dies |

### BossBar

| Value | Default | Effect |
|---|---|---|
| `bar_width` | 240 | Bar width (px), whatever the boss's health |
| `bar_height` | 4 | Bar height (px) |
| `border` | 1 | Frame thickness (px) |
| `bar_top` | 10 | Bar position under the name (px) |
| `loss_delay` | 0.4 | Loss segment hold before draining (s) |
| `loss_drain_speed` | 0.5 | Loss drain, in bar fractions per second |
| `hide_delay` | 1.0 | Time the bar stays after the fight (s) |
| `fill_color` | `#c8a040` | Current health |

## Extending

**A new boss:** make `actors/bosses/<name>/<name>.tscn` with the `Boss` script on the root (duplicating `otaman.tscn` is quickest). Keep the `Dormant`, `Roar`, `Decide`, `Stunned` and `Dead` states, and add one `BossAttack` subclass per attack pattern in `actors/bosses/<name>/states/`. On its `Damage`, turn off `flinches` and `stays_dead`.

**An arena:** instance `levels/objects/boss_arena.tscn` in the room's `Logic`, give its `Trigger` a shape that covers the fight, add `Gate` scenes (with `open` on) under its `Gates` node, and set `boss`. Put a rest point just outside the gates. For an intro, add a `Cutscene` beside the arena and set it as `intro`.

**A multi-part attack:** override `_next_phase()`, as `SaberCombo` (more swings) and `LeapSlam` (an active window that waits for landing) do.

**A third phase:** add a threshold (`[0.66, 0.33]`), a time scale, and set "Phase 3" on the attacks that should run in it.

## Known limitations

- Placeholder rectangles for the Otaman, its swings, slam, dash, shockwaves and pistol balls. No animations or sounds, and no boss music yet.
- One boss per arena. Fights with two bosses or summoned helpers aren't supported.
- The leap aims at where the player stands when it takes off and ignores walls in the way.
- The boss bar shows one bar only. There is no phase marker on it.
- Bosses don't jump onto platforms: standing on a plank keeps the player out of the combo's reach, but not the leap or the pistol.
