# Combat

Three small components in `components/combat/` handle all damage in the game: a **Hitbox** deals it, a **Hurtbox** receives it, and **Health** keeps count. They know nothing about the player, enemies or bosses, so every actor wires them up the same way.

## How it works

1. An attack turns its `Hitbox` on (`set_active(true)`). This enables its collision shapes.
2. A `Hurtbox` whose collision mask includes the hitbox's layer gets `area_entered` and reports it.
3. The hurtbox emits `hurt(hitbox)`, tells the hitbox with `register_hit()` (which emits the hitbox's `hit_landed`), then, if its `health` is set, calls `health.take_hit(hitbox)`. The damage is the hitbox's `damage` scaled by the attacker's [stats](/systems/stats#damage-and-resistance), then lowered by the receiver's resistance to the hit's [element](#elements).
4. `Health` emits `health_changed(current, maximum)`, and `died` when it reaches 0. `Health.kill()` drops it straight to 0 for instant deaths such as pits.
5. The owner listens to these signals and reacts (flash, knockback, respawn...).

The attack turns the hitbox off again after its active window. Turning a hitbox off and on counts as a new contact, so **each activation hits each hurtbox at most once**. A single swing never deals damage twice, however many frames it overlaps.

```
Player                                   TrainingDummy
└── Visual                               ├── Hurtbox ──hurt──► HurtFeedback, dummy tilts
    └── Attacks/Side ──area_entered──►   │      ├──register_hit──► Hitbox.has_hit()
        (player_attacks layer)           │      └──take_hit──► Health
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
| Player `Hurtbox` | none | `enemy_attacks` (5), `hazards` (6) |
| Hazard `Hitbox` | `hazards` (6) | none |
| `Spikes` | `hazards` (6) | `player` (2) |

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

The `attack_speed` [stat](/systems/stats) divides the startup and recovery of every attack state (combo strikes, lunge and riposte included). The active window is left alone, so a faster swing reaches as far.
### Movement during attacks

| Attack | Movement | Facing |
|---|---|---|
| SideAttack, ground | Stops dead | Pushing the other way turns the player around mid-swing; the hitbox turns with them |
| UpAttack, ground | Stops dead | Locked |
| CrouchAttack | Stops dead | Locked |
| SideAttack / UpAttack, air | Full air control | Locked |

Whether the swing counts as a ground or an air swing is decided when it starts. Attacking on the ground is a commitment: you plant your feet to swing. In the air you keep drifting, so air attacks stay useful while jumping over enemies. Gravity always applies. Jumping and dashing aren't possible until the swing ends.

### Re-swing after a miss

If a swing **missed**, pressing attack during its recovery cuts the recovery short and starts the next swing immediately (in whatever direction is held then). A swing that **hit** plays out its full recovery. This keeps whiffing cheap to correct, while landing hits keeps its rhythm.

The miss check uses `Hitbox.has_hit()`, which is reset each time the hitbox turns on. What happens on a press during recovery is decided by `PlayerAttackState.chain_state()`: the default is the re-swing above, and combo attacks override it.

### Ground combo

Ground side swings chain into a combo:

1. A ground **SideAttack** that hit, with attack pressed during its recovery, goes straight into another SideAttack. The chain has started.
2. Inside a chain every side swing chains on the next press, hit or not, so one miss doesn't drop the combo.
3. A swing that hits once `heavy_after_hits` (2) swings of the chain have hit goes into **ComboHeavy** instead: a slower swing that steps forward and hits harder, with a heavy reaction.
4. Without a combo skill the chain ends with the heavy swing. With one learned (see [Skills](/systems/skills)), attack during its recovery goes into a finisher, picked by the best combo skill and the stick at the press:

| Skill | Stick | Finisher |
|---|---|---|
| `combo_1` | any | **ComboFinisher**: a long forward lunge into a wide heavy slash |
| `combo_2` | up | **ComboFinisherUp**: hops the player up with a tall rising slash that knocks up and forward |
| `combo_3` | down | **ComboFinisherDown**: a planted slam that hits both sides along the ground and knocks enemies up |

With `combo_2` or `combo_3`, any other direction still gives the forward finisher. A chain only continues while the player stays on the ground and keeps pressing attack without up or down; an up or crouch swing starts over. Air side swings never chain.

`ComboHeavy` and the finishers share `PlayerComboStrike` (`combo_strike.gd`): its own startup, active and recovery times, a forward step during the wind-up on the ground (`lunge_speed`) and an upward hop when it starts on the ground (`rise_speed`). Facing is locked.

### Skill attacks

Four more attacks come from [skills](/systems/skills). Each line has an ability node under the player's `Skills` node that decides when the attack starts and how strong it is from the learned level, and a state in `actors/player/states/skills/`.

**Charged slash** (`PlayerChargedAttack`, states Charge and ChargedSlash). Keep holding attack through a ground side slash: when the swing ends it goes into **Charge**, planted. After `charge_time` (level 1) or `swift_charge_time` (level 2+) the charge is full and a glow shows above the head. Letting go when full releases the **ChargedSlash**, a wide heavy slash with a small step forward; letting go earlier cancels back to Idle. At level 3 the slash also sends a `ChargedWave` along the ground.

**Lunge** (`PlayerLungeAttack`, state Lunge). Attack pressed during a dash turns it into a thrust that drives forward with its hitbox on the whole way, hitting every enemy it passes. Speed, length and damage come from the level. While it lasts the player's hurtbox ignores `continuous` hitboxes (contact damage), so it runs through enemies; swings and hazards still hit. Leaving the ground stops the drive.

**Dive** (`PlayerDiveAttack`, state Dive). In the air, not rising, with down held and attack held for `hold_time`, and at least `min_height` of air below: the player hangs for a moment, plunges straight down (`DivePlunge` hitbox on) and lands with `DiveLanding` (`DiveLandingWide` from level 2) on for a moment, a shake and a rumble. At level 3, a dive that started `shockwave_height` or more above the ground adds a `DiveShockwave`. Invincible from the start until it lands, and it never ends in a hard landing. Pressing down + attack in the air first gives a side slash; holding on turns it into the dive.

**Ranged bolt** (`PlayerRangedAttack`, state Ranged). Pressing and letting go of the `ranged` button in Idle, Run, Jump or Fall throws a `RangedBolt` for `spirit_cost` spirit, if there is enough and no bolt is flying. On the ground the player stops; in the air they hang still until the bolt is out. The bolt flies straight and vanishes; at level 2 it slows down, turns and flies back to the player, able to hit again; at level 3 it also bursts (`BoltBurst`) where it turns.

Projectiles and blasts live in `actors/player/attacks/`. `PlayerProjectile` (a `Hitbox` that flies; the bolt and the wave) is added next to the player, ends on a wall (`world` layer) and is removed on a room change. `PlayerBlast` (a `Hitbox` that hits once and frees itself; the burst and the shockwave) can shake the camera.

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
| `Visual/Attacks/ComboHeavy` | (18, -16) | 28×22 | (1, 0) |
| `Visual/Attacks/Finisher` | (20, -16) | 36×26 | (1, 0) |
| `Visual/Attacks/FinisherUp` | (12, -34) | 26×40 | (0.4, -1) |
| `Visual/Attacks/FinisherDown` | (0, -6) | 64×12 | (0, -1), pushes away from the player |
| `Visual/Attacks/ChargedSlash` | (22, -16) | 44×30 | (1, 0) |
| `Visual/Attacks/Lunge` | (14, -16) | 26×20 | (1, 0) |
| `Visual/Attacks/DivePlunge` | (0, 4) | 16×12 | (0, -1) |
| `Visual/Attacks/DiveLanding` | (0, -6) | 40×14 | (0, -1) |
| `Visual/Attacks/DiveLandingWide` | (0, -7) | 72×16 | (0, -1) |

Positions are relative to the player's feet, facing right.

## Parry and riposte

Parrying turns an enemy's swing into an opening. Press **parry** on the ground, in Idle or Run, and the player raises a guard for a short window:

```
Idle / Run ──parry──► Parry: GUARD (parry_window)
                        │ parryable hit lands ──► SUCCESS: no damage, attacker stunned, invincible
                        │ heavy hit lands ──► GuardSlide: no damage, slid back (see Guard slide)
                        │                           ├─ attack within riposte_window ──► Riposte
                        │                           └─ window over ──► Idle / Run
                        └ nothing caught ──► FAILED: stuck for fail_recovery ──► Idle / Run
```

1. The **Parry** state turns on `Hurtbox.parrying` for `parry_window`. The player is planted and shows a placeholder `Guard` bar.
2. A hitbox with **`parryable`** on that reaches a parrying hurtbox is deflected: the hurtbox emits `parried(hitbox)` and calls `hitbox.register_parry()`, which emits the hitbox's own `parried(hurtbox)`. No damage, no `hurt`, no invincibility check.
3. The player turns to the attacker, becomes invincible, and gets a hit-stop, camera shake and rumble (`PlayerParry.play_feedback()`).
4. The attacker's `EnemyAttackState` hears `parried` and calls `EnemyDamage.stun()`: the enemy is pushed back and goes **Stunned** for `stun_time`. See [Enemies](/systems/enemies#stun).
5. Pressing attack within `riposte_window` starts the **Riposte**: a short lunge into a heavy slash (60 damage, HEAVY reaction), invincible from start to finish. Without the press the player returns to Idle or Run.
6. After a parry or riposte ends, invincibility lasts `grace_time` more.

A guard that catches nothing leaves the player stuck in place for `fail_recovery`, open to the attack they mistimed. That is the cost of parrying: pressing too early is punished as much as not pressing at all.

**What can be parried:** only hitboxes with `parryable` on. Telegraphed melee swings are parryable; contact damage, hazards and projectiles (the musketeer's ball) are not, and still hit during the guard. The raider's `Slash`, the shieldbearer's `Thrust` and the crow's `Talons` are parryable. The boar's `Gore` is not, but it is HEAVY, so the guard takes it as a [guard slide](#guard-slide).

## Guard slide

A heavy blow can't be parried, but a guard raised in time still catches it: the player takes no damage and is pushed back along the ground, then recovers. It rewards the same timing as a parry against attacks that can't be turned into an opening.

```
Parry: GUARD ──heavy hit──► GuardSlide: hit-stop, then slide away (slide_time), invincible
                              ├─ last recover_window, dash held ──► Dash (towards the attacker)
                              ├─ wall or end of slide ──► Idle / Run
                              └─ runs off a ledge ──► Fall
```

1. While `Hurtbox.parrying` is on, a hitbox for which **`can_guard_slide()`** is true is taken as a guard slide. That is a HEAVY hit, or any hit with `guard_slide` on, unless it is `unblockable`, `continuous` (contact damage and hazards) or `parryable` (that hit is parried instead).
2. The hurtbox emits `guard_slid(hitbox)` and calls `hitbox.register_guard_slide()`, which emits the hitbox's own `guard_slid(hurtbox)`. No damage, no `hurt`, no invincibility check. An attack that should react to being guarded listens to the hitbox's signal; an `EnemyProjectile` vanishes.
3. The Parry state hands the hit to `PlayerGuardSlide.start()` and enters **GuardSlide**. The slide goes the way the hit pushes (`Hitbox.push_direction()`), `knockback_force × distance_per_force` pixels: the Otaman's slam (160) slides 56 px, the boar's gore (220) 77 px.
4. A hit-stop, camera shake and rumble play first. The slide starts when the freeze ends, fast and slowing down (`slide_ease`). The player faces the attacker and is invincible throughout.
5. In the last `recover_window` the guard bar drops, and holding **dash** (with the dash off cooldown) cancels into a dash towards the attacker.
6. A wall stops the slide early. Running off a ledge drops into Fall. After the slide, invincibility lasts `grace_time` more.

The slide fills no spirit and gives no riposte window: it only saves the player from the hit.

## Blocking

A hurtbox can turn hits away with a **guard**: `Hurtbox.guard` is an optional `Callable` that gets the hitbox before it lands and returns true to block it. The shieldbearer's shield sets it (see [Enemies](/systems/enemies#shieldbearer)).

A blocked hit deals no damage and doesn't emit `hurt`. The hurtbox emits `blocked(hitbox)` and calls `hitbox.register_block()`, which emits the hitbox's own `blocked(hurtbox)`. The hit doesn't count as landed (`has_hit()` stays false), so it fills no spirit, sets off no on-hit item effects and doesn't chain a combo. A `PlayerProjectile` that is blocked vanishes.

The guard runs after the parry and invincibility checks.

The parry check runs before the invincibility check, so a guard raised while still blinking from an earlier hit can still parry.

## Reactions

Each hitbox has a `reaction` that tells the receiver how hard to react. The hitbox only carries the label; each actor decides what it means.

A [critical hit](/systems/stats#critical-hits) multiplies the scale below by another 1.5.

| Reaction | Player | Enemies | Hit-stop and shake (`feedback_scale()`) |
|---|---|---|---|
| `LIGHT` | Damage, flash and invincibility only. No stagger, no knockback, keeps doing what they were doing | Damage and flash only | ×0.5 |
| `NORMAL` | **Hurt** for `hurt_duration` with `hurt_knockback`, turns to face the hit | **Hurt** with `hurt_knockback`, turns to face the hit, unless mid-attack. See [Enemies](/systems/enemies#hit-reactions) | ×1 |
| `HEAVY` | **Hurt** for `heavy_hurt_duration` with `heavy_knockback` | **Hurt** with `heavy_knockback` | ×2 |

All current attacks are `NORMAL`. `LIGHT` and `HEAVY` are ready for upgraded player attacks and tougher enemies.

`Hitbox.push_direction(target)` gives the side a hit pushes towards. It follows the knockback, and a hitbox that pushes straight up or down (spikes, up slashes, enemy contact) pushes away from its own centre instead. Both the player and enemies use it.

## Hit feedback

`HurtFeedback` (`components/combat/hurt_feedback.gd`) listens to a hurtbox and, on every accepted hit:

1. Flashes `flash_target` with an over-bright `modulate` (works because 2D HDR is on).
2. Freezes the game for `hit_stop` seconds through the `HitStop` autoload.
3. Asks for `shake` camera trauma through `Events.camera_shake_requested`.
4. Rumbles the gamepad with `rumble` strength for `rumble_time` seconds through the `Rumble` autoload.

Steps 2 to 4 are scaled by the hit's reaction. The values sit on the **receiver**, so each actor sets how much a hit on it is felt: getting hit as the player freezes longer, shakes harder and rumbles more than landing a hit on the dummy. See [Game feel](/systems/game-feel) for the freeze, shake and rumble themselves.

## Invincibility

A hurtbox with `invincibility_time` above 0 ignores every hit for that long after accepting one. The training dummy has none. The player's Hurt state holds invincibility with `set_invincible_for(INF)` and, when it ends, sets it to `invincibility_time` (see [Player](/systems/player#taking-damage)).

`InvincibilityBlink` (`components/combat/invincibility_blink.gd`) is a separate node that blinks a `CanvasItem` while a hurtbox is invincible. Point its `hurtbox` and `target` at the right nodes. Any actor can use it.

`set_invincible_for(seconds)` replaces the remaining time, and `clear_invincibility()` ends it early, for example on respawn.

## Elements

Each hitbox has an `element` that says what kind of harm it does. Actors with [stats](/systems/stats) resist each element separately (`normal_resist`, `contact_resist`, `fire_resist`, `poison_resist`). The element changes nothing else: reactions, knockback and feedback stay the same.

| Element | Used by |
|---|---|
| `NORMAL` | Every attack swing and projectile, turret bolts, spike traps (default) |
| `CONTACT` | Enemy contact damage (raider, musketeer) |
| `FIRE` | Fire traps |
| `POISON` | Poison zones |

## Hazards

### Spikes

Spikes (`levels/objects/spikes.gd`) aren't a `Hitbox`: they kill the player instantly, like a pit, and the death leaves a [death mark](/systems/death-penalty) like any other. To keep them fair, they only kill when the player really steps in: the player's centre must be within the spikes' width and their feet at least `sink_depth` (2 px) below the top. Brushing a corner or the side mid-jump does nothing, so spikes can always be jumped over. The player stops dead where they stand. Spikes stay on the `hazards` layer so [safe ground](/systems/death-penalty#safe-ground) keeps away from them. Enemies ignore them.

### Damaging hazards

A damaging hazard is a `Hitbox` that is always on: `active_on_start` and **`continuous`** enabled, on the `hazards` layer.

Hurtboxes normally react only to *new* contacts. Without `continuous`, a player who lands in spikes and stays there would be hit once and then never again. When a hurtbox's invincibility ends, it checks what it still overlaps, and a `continuous` hitbox it is still inside hits it again. Attack swings must not be `continuous`, or one swing could hit a target with invincibility frames twice.

A hazard that pushes straight up with `knockback_force` 0 pushes the player away from its centre instead. Enemy contact damage works the same way, see [Enemies](/systems/enemies#contact-damage).

## Training dummy

`actors/training_dummy/` is a stationary target placed in the test room. It has a `Hurtbox`, a `Health` (100), a `HurtFeedback` (flash, 0.05 s hit-stop, 0.3 shake, 0.3 rumble) and a small health bar. When hit it also tilts away from the hit. At 0 health it disappears, then rebuilds with full health after `respawn_delay`.

It has no behaviour of its own, so unlike other actors it has no `states/` folder.

## Files

| File | Role |
|---|---|
| `components/combat/hitbox.gd` | `Hitbox`: damage, element and knockback, `roll_critical()`, `get_damage()`, `set_active()`, `has_hit()`, `hit_landed` |
| `components/combat/hurtbox.gd` | `Hurtbox`: detects hitboxes, invincibility, emits `hurt` |
| `components/combat/health.gd` | `Health`: hit points, `take_hit()` with resistances, maximum from stats, `health_changed` and `died` |
| `components/combat/invincibility_blink.gd` | `InvincibilityBlink`: blinks a visual while a hurtbox is invincible |
| `components/combat/hurt_feedback.gd` | `HurtFeedback`: flash, hit-stop, camera shake and rumble on every accepted hit |
| `actors/player/states/attacks/player_attack_state.gd` | `PlayerAttackState`: swing phases, re-swing, planted on the ground / air control in the air |
| `actors/player/states/attacks/side_attack.gd` | Side slash, turns around on the ground, chains the ground combo |
| `actors/player/states/attacks/combo_strike.gd` | `PlayerComboStrike`: heavy combo swing with its own timing, lunge and hop |
| `actors/player/states/attacks/combo_heavy.gd` | ComboHeavy: the heavy end of the chain, picks the finisher from the learned combo skill |
| `actors/player/states/skills/charge.gd` | Charge: planted, attack held, full after the charge time |
| `actors/player/states/skills/charged_slash.gd` | ChargedSlash: heavy slash, fires the wave at level 3 |
| `actors/player/states/skills/lunge.gd` | Lunge: thrust forward, ignores contact damage |
| `actors/player/states/skills/dive.gd` | Dive: hang, plunge, land, recover |
| `actors/player/states/skills/ranged.gd` | Ranged: throw the bolt |
| `actors/player/attacks/player_projectile.gd` | `PlayerProjectile`: flying hitbox, straight or returning, bursts at the turn |
| `actors/player/attacks/player_blast.gd` | `PlayerBlast`: one-off hitbox that frees itself, optional shake |
| `actors/player/attacks/*.tscn` | `RangedBolt`, `ChargedWave`, `BoltBurst`, `DiveShockwave` |
| `actors/player/states/attacks/up_attack.gd` | Up slash |
| `actors/player/states/attacks/crouch_attack.gd` | Low slash (ground only) |
| `actors/player/abilities/parry.gd` | `PlayerParry`: parry and riposte tuning, `wants()`, success feedback |
| `actors/player/states/parry.gd` | Guard, success and failed phases |
| `actors/player/states/attacks/riposte.gd` | Lunging heavy slash after a parry |
| `actors/player/abilities/guard_slide.gd` | `PlayerGuardSlide`: guard slide tuning, the slide resolved from the hit, feedback |
| `actors/player/states/guard_slide.gd` | Sliding back after a heavy hit caught on the guard, dash cancel |
| `actors/training_dummy/training_dummy.tscn` | Dummy scene |
| `actors/training_dummy/training_dummy.gd` | Hit reaction, break and rebuild |

## Tuning

### Hitbox

| Value | Default | Effect |
|---|---|---|
| `damage` | 20 | Base damage per hit, scaled by the attacker's `damage` stat |
| `element` | NORMAL | Kind of harm, resisted per element. See [Elements](#elements) |
| `knockback_force` | 120 | Knockback strength (px/s) |
| `knockback_direction` | (1, 0) | Direction when facing right, mirrored when flipped |
| `reaction` | NORMAL | How hard the receiver reacts: LIGHT, NORMAL or HEAVY. See [Reactions](#reactions) |
| `active_on_start` | false | On for hazards that always hurt |
| `continuous` | false | Hits a hurtbox again when its invincibility ends while still inside. For hazards |
| `parryable` | false | A parrying hurtbox deflects this hit instead of taking it. For telegraphed melee swings |
| `guard_slide` | false | A parrying hurtbox takes this hit as a [guard slide](#guard-slide) even if it isn't HEAVY |
| `unblockable` | false | Never a guard slide, even when HEAVY: the hit lands through the guard |

### Hurtbox

| Value | Default | Effect |
|---|---|---|
| `health` | none | `Health` node that takes the damage automatically |
| `invincibility_time` | 0 | Immunity after a hit (s). 0 means every new hit counts. The player sets its own from `PlayerDamage.invincibility_time` |
| `rewards_attacker` | true | Off for props: hits on it fill no spirit |

`guard` (a `Callable`, not exported) is set from code. See [Blocking](#blocking).

### HurtFeedback

| Value | Default | Effect |
|---|---|---|
| `hurtbox` | none | Hurtbox to listen to |
| `flash_target` | none | Node that flashes. None means no flash |
| `flash_color` | (3, 3, 3) | Flash colour, above 1 overbrightens |
| `crit_flash_color` | (3, 2.2, 0.6) | Flash colour of a [critical hit](/systems/stats#critical-hits) |
| `flash_time` | 0.12 | Fade back from the flash (s) |
| `hit_stop` | 0 | Freeze length (s) at NORMAL. Player 0.1, dummy 0.05 |
| `shake` | 0 | Camera trauma at NORMAL (0 to 1). Player 0.6, dummy 0.3 |
| `rumble` | 0 | Gamepad rumble strength at NORMAL (0 to 1). Player 0.8, raider, musketeer and dummy 0.3 |
| `rumble_time` | 0.15 | Rumble length (s) at NORMAL |

### InvincibilityBlink

| Value | Default | Effect |
|---|---|---|
| `hurtbox` | none | Hurtbox whose invincibility is shown |
| `target` | none | Node that blinks |
| `interval` | 0.06 | Seconds per on/off step |

### Health

| Value | Default | Effect |
|---|---|---|
| `max_health` | 100 | Starting and maximum health when `stats` is not set |
| `stats` | none | `Stats` node. Sets the maximum (`max_health` stat) and the resistances. The player's points at its `Stats` child |

### Player attack

Set on the `Player` node, group **Attack**.

| Value | Default | Effect |
|---|---|---|
| `attack_startup` | 0.05 | Wind-up before the hitbox turns on (s) |
| `attack_active` | 0.1 | How long the hitbox is on (s) |
| `attack_recovery` | 0.15 | Time after the hitbox turns off before the player can act (s) |
| `attack_buffer_time` | 0.12 | How early an attack press is remembered (s) |
| `attack_vertical_threshold` | 0.75 | How far up or down the stick must be held for an up or crouch attack |

The three basic attacks share this timing. The combo swings and the riposte have their own, see [Parry and riposte tuning](#parry-and-riposte-1). Damage and knockback are set per attack on the hitboxes under `Visual/Attacks` in `player.tscn`.

### Ground combo

`SideAttack.heavy_after_hits` = 2: hits in one chain that lead into ComboHeavy.

Set on each state node under `StateMachine`:

| State | `startup` | `active` | `recovery` | `lunge_speed` | `rise_speed` | Hitbox damage | Knockback |
|---|---|---|---|---|---|---|---|
| ComboHeavy | 0.1 | 0.12 | 0.3 | 120 | 0 | 40 | 170 |
| ComboFinisher | 0.12 | 0.14 | 0.35 | 180 | 0 | 60 | 220 |
| ComboFinisherUp | 0.06 | 0.16 | 0.3 | 0 | 260 | 60 | 200 |
| ComboFinisherDown | 0.14 | 0.1 | 0.4 | 0 | 0 | 60 | 160 |

`PlayerComboStrike` defaults are 0.08 / 0.12 / 0.28 with no lunge or hop. Every combo hitbox has the heavy reaction.

### Skill attacks

`PlayerChargedAttack` (`Skills/Charged`):

| Value | Default | Effect |
|---|---|---|
| `charge_time` | 1.5 | Seconds to a full charge at level 1 |
| `swift_charge_time` | 0.75 | Seconds to a full charge at level 2 and 3 |
| `wave_offset` | (16, -10) | Where the wave starts, facing right |

ChargedSlash state: `startup` 0.05, `active` 0.14, `recovery` 0.35, `lunge_speed` 60. Hitbox damage 80, knockback 240, heavy.

`PlayerLungeAttack` (`Skills/Lunge`), per level 1 / 2 / 3:

| Value | Default | Effect |
|---|---|---|
| `speeds` | 260 / 320 / 380 | Forward speed (px/s) |
| `durations` | 0.25 / 0.32 / 0.4 | Seconds the hitbox is on and the thrust drives |
| `damages` | 40 / 60 / 100 | Damage, written onto the Lunge hitbox |

Lunge state: `startup` 0.03, `recovery` 0.2. Hitbox knockback 180, heavy.

`PlayerDiveAttack` (`Skills/Dive`) and the Dive state:

| Value | Default | Effect |
|---|---|---|
| `hold_time` | 0.18 | Seconds attack must be held with down |
| `min_height` | 40 | Air needed below the feet to dive (px) |
| `shockwave_height` | 96 | Level 3: height for the shockwave (px) |
| `Dive.hang_time` | 0.12 | Hang before the plunge (s) |
| `Dive.plunge_speed` | 480 | Fall speed of the plunge (px/s) |
| `Dive.land_time` | 0.1 | Seconds the landing hitbox is on |
| `Dive.recover_time` | 0.25 | Planted after landing (s) |
| `Dive.land_shake` | 0.6 | Camera shake on landing |

Hitbox damage: plunge 40, landing 60, wide landing 60, shockwave 80 (heavy, shake 0.8).

`PlayerRangedAttack` (`Skills/Ranged`) and the Ranged state:

| Value | Default | Effect |
|---|---|---|
| `spirit_cost` | 6 | Spirit per bolt |
| `bolt_offset` | (12, -18) | Where the bolt starts, facing right |
| `Ranged.fire_delay` | 0.1 | Seconds before the bolt leaves |
| `Ranged.cast_time` | 0.3 | Length of the throw (s) |

`PlayerProjectile` defaults (the bolt uses them): `start_speed` 120, `max_speed` 280, `acceleration` 900, `lifetime` 0.4, `turn_time` 0.15, `catch_distance` 12, `catch_height` 16. The wave overrides `start_speed` 160, `max_speed` 320, `lifetime` 0.45. Damage: bolt 2, wave 3 (heavy), burst 2 (shake 0.3). `PlayerBlast.duration` defaults to 0.15 (shockwave 0.2).

### Parry and riposte

Set on the player's **`Parry`** child node (`PlayerParry`). The guard and riposte windows are player stats, see [Stats](/systems/stats#tuning) (`parry_window` 0.25 s, `riposte_window` 0.5 s).

| Group | Value | Default | Effect |
|---|---|---|---|
| Timing | `fail_recovery` | 0.35 | Time stuck in place after a guard that caught nothing (s) |
| Timing | `grace_time` | 0.3 | Invincibility after a parry or riposte ends (s) |
| Feedback | `hit_stop` | 0.12 | Freeze on a successful parry (s) |
| Feedback | `shake` | 0.35 | Camera trauma on a successful parry |
| Feedback | `rumble` | 0.6 | Gamepad rumble strength on a successful parry |
| Feedback | `rumble_time` | 0.15 | Rumble length (s) |

Set on the **`Riposte`** state node:

| Value | Default | Effect |
|---|---|---|
| `startup` | 0.06 | Wind-up before the hitbox turns on (s). The player lunges forward during it |
| `active` | 0.12 | How long the hitbox is on (s) |
| `recovery` | 0.3 | Time after the hitbox turns off (s) |
| `lunge_speed` | 160 | Forward speed during the wind-up (px/s) |

The `Visual/Attacks/Riposte` hitbox at (18, -16), 28×20, deals 60 damage with a HEAVY reaction and `knockback_force` 180.

### Guard slide

Set on the player's **`GuardSlide`** child node (`PlayerGuardSlide`).

| Group | Value | Default | Effect |
|---|---|---|---|
| Slide | `distance_per_force` | 0.35 | Pixels slid per point of the hit's `knockback_force` |
| Slide | `slide_time` | 0.5 | How long the slide takes, after the hit-stop (s) |
| Slide | `slide_ease` | 0.4 | Ease of the slide; below 1 starts fast and slows down |
| Slide | `recover_window` | 0.35 | Last part of the slide (s): the guard drops and a held dash cancels it |
| Slide | `grace_time` | 0.1 | Invincibility after the slide ends (s) |
| Feedback | `hit_stop` | 0.1 | Freeze when the hit is caught (s) |
| Feedback | `shake` | 0.4 | Camera trauma when the hit is caught |
| Feedback | `rumble` | 0.7 | Gamepad rumble strength when the hit is caught |
| Feedback | `rumble_time` | 0.2 | Rumble length (s) |

### Training dummy

| Value | Default | Effect |
|---|---|---|
| `respawn_delay` | 1.5 | Seconds before a broken dummy rebuilds |
| `hit_tilt_degrees` | 14 | How far it tilts when hit |

Its health is set on its `Health` child node.

## Extending

**A new damageable actor:** add a `Health` node and a `Hurtbox` (an `Area2D` with the `Hurtbox` script and a `CollisionShape2D`). Set the hurtbox's mask to the attack layer that should hurt it, point its `health` at the `Health` node, and connect `hurt` and `died` in the actor's root script.

**A new attack:** add a `Hitbox` (an `Area2D` with the `Hitbox` script and a shape) under the actor's `Visual` node, on its attack layer. Add a state that calls `set_active(true)` and `set_active(false)` at the right times, and `set_active(false)` in `exit()`.

**A new player attack:** add a hitbox under `Visual/Attacks`, a script in `actors/player/states/attacks/` that extends `PlayerAttackState` (override `move()` for different movement), a state node pointing its `hitbox` at the new hitbox, a name constant in `PlayerState`, and a rule in `PlayerState.attack_state()`.

**Spikes:** an `Area2D` with the `Spikes` script and a `RectangleShape2D` child named `Shape`, on the `hazards` layer with mask `player`, sitting on the ground.

**A damaging hazard:** a `Hitbox` on the `hazards` layer with `active_on_start` and `continuous` enabled.

## Known limitations

- A hurtbox without invincibility only reacts to *new* contacts, so a `continuous` hitbox only repeats against hurtboxes that have invincibility frames.
- The combo finishers, charged slash, lunge, dive and projectiles are placeholder rectangles with no animation or sound.
- Projectiles fly through one-way platforms and are only stopped by solid tiles.
- The charge can't be cancelled into a dash or parry; only letting go or a hit ends it.
- No crouch state yet: the crouch attack doesn't lower the player's body, it only swings low.
- The three basic attacks share one set of timings.
- Parrying is ground only, and only from Idle or Run: it can't cancel an attack, a dash or a hurt stagger.
- No parry sound or guard animation, and the riposte isn't a special finishing move: it is a strong slash.
- The guard slide has no slide animation, dust or impact effect: the guard bar flashes and the placeholder body moves. It only slides along flat ground; slopes don't exist yet.
- No enemy reacts to a guard slide yet; `Hitbox.guard_slid` is there for attacks that should.
- Placeholder rectangles for the slash and the dummy.
- A blocked hit has no recoil on the attacker and no block sound: only the shield flashes.
