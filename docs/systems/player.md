# Player

The player is a `CharacterBody2D` driven by a [state machine](/architecture/state-machine).

## Files

| File | Role |
|---|---|
| `actors/player/player.tscn` | Scene: body, collision, visuals, camera, state machine |
| `actors/player/player.gd` | `Player`: tuning values, timers and helper functions shared by states |
| `actors/player/player_damage.gd` | `PlayerDamage`: reacts to hits (knockback, which state), hurt and death tuning, reports health to `Events` |
| `actors/player/abilities/drop_through.gd` | `PlayerDropThrough`: down + jump through one-way platforms |
| `actors/player/abilities/ladder_climb.gd` | `PlayerLadderClimb`: finds ladders to grab, climbing tuning |
| `actors/player/abilities/ledge_grab.gd` | `PlayerLedgeGrab`: finds ledges to grab, hang and climb tuning |
| `actors/player/abilities/flasks.gd` | `PlayerFlasks`: healing flask charges, drinking and refilling, reports them to `Events` |
| `actors/player/abilities/parry.gd` | `PlayerParry`: parry and riposte tuning, when a parry starts, success feedback |
| `actors/player/abilities/skills.gd` | `PlayerSkills`: learned skills, see [Skills](/systems/skills) |
| `actors/player/skills/` | `PlayerSkill` resource, one folder per skill line with its `.tres` files and ability script |
| `actors/player/attacks/` | Player projectiles and blasts (bolt, wave, burst, shockwave) |
| `actors/player/states/player_state.gd` | `PlayerState`: base class with a typed `player` reference and state name constants |
| `actors/player/states/*.gd` | One script per state |

## Scene tree

```
Player (CharacterBody2D)     layer: player   mask: world, platforms   group: "player"
├── CollisionShape2D         12×30 rectangle, origin at the feet
├── Visual (Node2D)          flipped with scale.x to face left/right
│   ├── HealAura (ColorRect) placeholder glow behind the body while drinking a flask
│   ├── Body (ColorRect)     placeholder
│   ├── Eye (ColorRect)      placeholder, shows facing direction
│   ├── Guard (ColorRect)    placeholder bar in front, shown while the parry guard is up
│   └── Attacks (Node2D)     one Hitbox per attack, layer: player_attacks
│       ├── Side  ├── Up  ├── Crouch  ├── Riposte   each with a Shape and a placeholder Slash
│       ├── ComboHeavy  ├── Finisher  ├── FinisherUp  ├── FinisherDown
│       └── ChargedSlash  ├── Lunge  ├── DivePlunge  ├── DiveLanding  └── DiveLandingWide
├── Health                   5 hit points
├── Hurtbox (Area2D)         10×26, mask: enemy_attacks, hazards
├── InvincibilityBlink       blinks Visual while the hurtbox is invincible
├── Damage                   PlayerDamage: hit reactions and hurt/death tuning
├── HurtFeedback             flash, hit-stop 0.1 s, shake 0.6
├── DropThrough              PlayerDropThrough: down + jump through one-way platforms
├── LadderClimb              PlayerLadderClimb: finds ladders, climbing tuning
├── LedgeGrab                PlayerLedgeGrab: finds ledges, hang and climb tuning
├── Flasks                   PlayerFlasks: healing flask charges
├── Parry                    PlayerParry: parry and riposte tuning
├── Camera2D                 smoothed, limited by the room's bounds
│   └── CameraShake          shakes on Events.camera_shake_requested
└── StateMachine
    ├── Idle  ├── Run  ├── Jump  ├── Fall  ├── Dash  ├── Climb  ├── LedgeHang  ├── LedgeClimb
    ├── HardLanding  ├── Heal
    ├── SideAttack  ├── UpAttack  ├── CrouchAttack  ├── Parry  ├── Riposte
    ├── ComboHeavy  ├── ComboFinisher  ├── ComboFinisherUp  ├── ComboFinisherDown
    ├── Charge  ├── ChargedSlash  ├── Lunge  ├── Dive  ├── Ranged
    └── Hurt  └── Dead
```

## States and transitions

| State | Does | Leaves to |
|---|---|---|
| **Idle** | Gravity, slows to a stop | Fall (not on floor, or dropping through a platform), Climb (up at a ladder, or down on top of one), Jump (jump buffered), Dash, Parry (parry pressed), Ranged (ranged let go, with the skill), an attack (attack buffered), Heal (heal pressed), Run (move input) |
| **Run** | Gravity, accelerates toward `run_speed` | Fall (also when dropping through a platform), Climb, Jump, Dash, Parry, Ranged, an attack, Heal, Idle (no move input) |
| **Jump** | Sets upward velocity, cuts the jump if the button is released | Climb (up at a ladder), Ranged, Dive (down + attack held, with the skill), an attack, Fall (once moving down) |
| **Fall** | Gravity, air control | Jump (coyote time), Climb (up at a ladder), LedgeHang (falling past a ledge it faces), Ranged, Dive, an attack, Idle/Run (landed), HardLanding (landed after a long fall) |
| **Dash** | Ground only. Fixed horizontal speed, no gravity | Lunge (attack, with the skill), Idle/Run (time is up), Fall (ran off a ledge: ends at once) |
| **Climb** | On a ladder: up and down move along it, no gravity, no attacks, one-way platforms off. See [Climbing ladders](#climbing-ladders) | Idle (reached the top or the ground), Jump (jump, straight up or to the side held), Fall (down + jump, or off the bottom) |
| **LedgeHang** | Hangs from a ledge by the hands: no gravity, no movement. See [Ledge grab](#ledge-grab) | LedgeClimb (up or jump, after `climb_delay`), Fall (down) |
| **LedgeClimb** | Pulls up onto the ledge: straight up beside the wall, then sideways onto the top. No input | Idle/Run (standing on the top) |
| **HardLanding** | Landed after falling `hard_landing_height` or more: stuck in place for `hard_landing_time`, camera shake. See [Hard landing](#hard-landing) | Idle/Run (time is up), Dash (in the second half), Fall (ground gone) |
| **Heal** | Drinks a healing flask: the flask is used and the health restored at once, then the player slows to a stop and stands still for `drink_time`. See [Healing flasks](#healing-flasks) | Idle/Run (time is up), Fall (ground gone) |
| **SideAttack / UpAttack / CrouchAttack** | One swing: startup, active (hitbox on), recovery. The direction comes from the vertical input when attack is pressed. See [Combat](/systems/combat#player-attacks) | Idle/Run (on floor), Fall (in air), another attack (re-swing after a miss), SideAttack or ComboHeavy (ground combo, see [Combat](/systems/combat#ground-combo)) |
| **Parry** | Planted guard for `parry_window`. A parryable hit is deflected and stuns the attacker; a guard that catches nothing leaves the player stuck for `fail_recovery`. See [Combat](/systems/combat#parry-and-riposte) | Riposte (attack after a parry), Idle/Run (time is up), Fall (ground gone) |
| **Riposte** | Invincible lunge into a heavy slash after a parry | Idle/Run (on floor), Fall (in air), another attack (re-swing after a miss) |
| **ComboHeavy** | Heavy last swing of the ground combo, steps forward | Idle/Run, Fall, a finisher (attack with a combo skill learned), another attack (re-swing after a miss) |
| **ComboFinisher / Up / Down** | Combo finishers learned as [skills](/systems/skills): forward lunge, rising hop, two-sided slam | Idle/Run, Fall, another attack (re-swing after a miss) |
| **Charge** | Planted, attack held after a ground side slash, glows when full. See [Combat](/systems/combat#skill-attacks) | ChargedSlash (let go when full), Idle/Run (let go early), Fall |
| **ChargedSlash** | Heavy charged slash, a wave at level 3 | Idle/Run, Fall, another attack (re-swing after a miss) |
| **Lunge** | Thrust forward from a dash, ignores contact damage | Idle/Run, Fall, another attack (re-swing after a miss) |
| **Dive** | Hang, plunge, land with a hit around, recover. Invincible until it lands | Idle/Run, Fall |
| **Ranged** | Throw a spirit bolt, stopped on the ground or hanging in the air | Idle/Run, Fall |
| **Hurt** | Entered from any state on a NORMAL or HEAVY hit. Knocked up and away, faces the hit, no control, invincible | Idle/Run (on floor), Fall (in air) after the stagger time |
| **Dead** | Entered from any state when health reaches 0. Dark tint, keeps its knockback and slides to a stop. In a pit (below the room's bottom edge) the body stops dead instead, so it doesn't drift under the floor and drag the camera. Reads no input | None: emits `Events.player_died` after `death_delay`, and the world's respawn (at the last rest point, or where the player entered the room) puts the player in Idle |

## Movement techniques

### Jump defined by height and time

Instead of tuning gravity and jump force directly, you set how **high** the jump goes and how **long** it takes. The physics values are derived:

```gdscript
jump_velocity = -2 * jump_height / jump_time_to_peak
jump_gravity  =  2 * jump_height / jump_time_to_peak²
fall_gravity  =  2 * jump_height / jump_time_to_fall²
```

Because `jump_time_to_fall` is shorter than `jump_time_to_peak`, the player falls faster than they rise, which feels weighty instead of floaty.

### Variable jump height

If the jump button is released while still moving up, upward velocity is multiplied by `jump_cut_multiplier` once. A tap gives a short hop (about 10 px), a hold gives the full jump (about 50 px).

### Coyote time

For `coyote_time` seconds after walking off a ledge, the player can still jump. This forgives late presses that look correct to the player.

### Jump buffering

A jump pressed up to `jump_buffer_time` seconds before landing is remembered and fires on landing. This forgives early presses.

### Dropping through platforms

Holding down and pressing jump while standing on a one-way platform drops the player through it instead of jumping. One-way tiles sit on their own `platforms` physics layer, so the drop (`PlayerDropThrough` on the `DropThrough` node) just switches that layer off in the player's mask for `drop_through_time` seconds, long enough to fall clear of the plank, then switches it back on.

The drop only happens when nothing solid is under the player: `drop_through.wants()` briefly turns the platforms layer off and checks one pixel down with `test_move()`. On solid ground, or with one foot on a solid block, down + jump is an ordinary jump. Down has to be held at least as far as `attack_vertical_threshold`, the same as for a crouch attack.

Dropping uses up the jump press and coyote time, so the player can't jump straight back up from mid-drop.

### Climbing ladders

A [ladder](/systems/rooms#ladders) is grabbed by holding up over it (on the ground or in the air), or by holding down while standing on its top. "Over it" means within `grab_reach` of its centre, with the ladder somewhere between the feet and `grab_height` above them; grabbing up also needs the ladder to go on above the feet. The player snaps to the ladder's centre and enters **Climb**. A ladder that hangs in the air is caught by the upper body while jumping at it, and the feet are pulled up onto its bottom.

In the air, a lighter push is enough (`air_grab_threshold` instead of `grab_threshold`), so a diagonal held while jumping at a ladder still catches it.

- **Up / down** move at `climb_speed`. With no input the player hangs still.
- **Reaching the top** puts the feet exactly on the ladder's top, on the plank there, and enters Idle. **Reaching the ground** while climbing down enters Idle. **Going past the bottom** of a ladder that hangs in the air lets go (Fall).
- **Jump** is a full jump off the ladder: straight up, or sideways at `run_speed` if a direction is held. No ladder can be grabbed while that jump still rises, so holding up doesn't snap you straight back on. Once it peaks, holding up over a ladder grabs it again. With up held and no direction, this makes jump a hop up the ladder.
- **Down + jump** just lets go and falls. The ladder can't be grabbed again for `regrab_delay`.

Holding up next to a ladder that stands on the ground grabs it at once. So holding up and then pressing jump is a jump off the ladder, and the player catches it again at the top of the jump.
- One-way platforms are off while climbing (`set_platforms_enabled(false)`), so the player passes through the plank at the top and any planks the ladder crosses.
- A hit knocks the player off into Hurt as usual.

Ladders can continue into another room through a [vertical exit](/systems/rooms#vertical-exits). The Climb state keeps going after the room changes: its ladder was freed with the old room, so it looks up the ladder at the new position (`PlayerLadderClimb.refind()`) and carries on. Ladders are found by position through the `ladders` group, not by physics, so this works on the very first frame of the new room.

### Ledge grab

Falling past the top of a solid wall while facing it grabs the ledge (**LedgeHang**). Nothing is placed by hand: `PlayerLedgeGrab.wants_grab()` checks the tiles each frame of Fall.

1. Only while moving down, not on the floor, and with down not held. It doesn't work for `regrab_delay` after dropping off a ledge.
2. A ray at hand height (`hand_height` above the feet, plus `snap_window`) looks `grab_reach` px ahead of the body for a wall on the `world` layer. One-way planks are never grabbed.
3. A ray down just inside the wall finds its top within `snap_window` of the hands. If the point it starts from is already solid, the wall goes on above the hands and there is no ledge.
4. There must be at least `min_drop` of air (no ground or platform) under the feet in the hanging position. So a wall has to be at least `hand_height` + `min_drop` (44 px, about 3 tiles) tall to be a ledge; lower steps, which a jump clears anyway, are never grabbed.
5. The body's shape must fit standing on the top, so ledges under a low ceiling aren't grabbed.

The player snaps to hang with the hands on the corner and the body against the wall, facing it.

- **Up or jump** climbs (after `climb_delay`, so a held up still shows the hang). **LedgeClimb** moves the body up beside the wall in `climb_rise_time`, then onto the top in `climb_over_time`. The path is L-shaped, so the body never cuts into the wall. It then ends in Idle or Run.
- **Down** lets go into Fall, and no ledge can be grabbed for `regrab_delay`.
- A hit knocks the player off into Hurt as usual.

With a 52 px jump and 28 px hands, walls from 3 to about 5 tiles (48 to 80 px) can be climbed from the ground; 1 and 2 tile steps are just landed on.

### Hard landing

The **Fall** state measures how far the player drops while moving down. Landing after `hard_landing_height` (160 px, 10 tiles) or more enters **HardLanding** instead of Idle/Run:

- The player can't move for `hard_landing_time` (0.5 s). Horizontal speed is held at 0 and no input is read.
- The camera shakes once (`Events.camera_shake_requested`, trauma 0.5).
- Once `hard_landing_dash_cancel` (half) of the time has passed, a dash gets the player out early.

The distance is counted from where the Fall state starts: the top of a jump, walking off a ledge, letting go of a ladder. It carries through room transitions, so falling through a hole into the room below counts as one drop. Air attacks start a new count. Ordinary jumps (52 px) and the 2-tile platform rules never come close.

### Dash

A fixed-speed horizontal burst along the ground in the input direction (or facing direction if there's no input). The cooldown prevents spamming.

Dash is a **ground move only** (`wants_dash()` needs `is_on_floor()`): it can't start while jumping, falling or climbing a ladder, and if jump and dash are pressed in the same frame, the jump wins. A dash that runs off a ledge ends at once; the player keeps `run_speed` and falls with normal air control.

### Healing flasks

The player carries `flask_count` healing flasks (the `Flasks` node, `PlayerFlasks`; both values are [stats](/systems/stats)). Pressing `heal` in Idle or Run enters **Heal**, which drinks one: it restores `flask_heal` health right away, then holds the player in place for `drink_time` while a placeholder aura (`Visual/HealAura`, the Heal state's `aura`) glows and fades out.

- Only on the ground, in Idle or Run: not in the air, on a ladder, mid-attack, mid-dash, hurt or during a hard landing.
- Heal does nothing at full health, so a flask is never wasted. Jump pressed in the same frame wins.
- With no flasks left, pressing heal (where it would otherwise work) sends `Events.player_flasks_empty`, and the HUD shakes the flask pips.
- The health is restored when drinking starts, so a hit during the drink interrupts it (Hurt, as from any state) but doesn't take the healing back. The risk is the time spent standing still.
- A [rest point](/systems/rest-points) refills every flask. So does respawning after death (`respawn(at)`).
- Every change is sent as `Events.player_flasks_changed(current, maximum)`, plus once on spawn (deferred), which drives the flask pips in the [HUD](/systems/hud).

Flasks aren't saved: loading a save puts the player on a rest point, which refills them anyway.

### Taking damage

1. A `Hitbox` on `enemy_attacks` or `hazards` touches the player's `Hurtbox`.
2. The hurtbox emits `hurt`. `HurtFeedback` flashes the player, freezes the game and shakes the camera.
3. `PlayerDamage` reads the hit's [reaction](/systems/combat#reactions). LIGHT stops here. NORMAL and HEAVY pick the knockback and stagger time, turn the player to face the hit and enter **Hurt**.
4. The hurtbox removes health. At 0, `Health.died` makes `PlayerDamage` enter **Dead** instead.

`PlayerDamage` also forwards every health change to `Events.player_health_changed`, which drives the [HUD](/systems/hud) health bar.

**Knockback direction:** the horizontal sign of the hitbox's knockback. A hitbox that pushes straight up (spikes) pushes the player away from its centre. If the player is exactly on the centre, they are pushed backwards.

**Invincibility** lasts through the whole Hurt state and for `invincibility_time` after it ends, so the player gets control back while still safe for a moment. A stagger that is longer (heavy hit) automatically gets longer protection. A LIGHT hit, which has no stagger, gives `invincibility_time` from the hit. The `InvincibilityBlink` node shows it by blinking `Visual`. While invincible, new hits are ignored completely: no damage, no knockback.

**Respawn** (`respawn(at)`) restores full health, refills the healing flasks, ends invincibility and clears the jump and attack buffers, so presses made while dead don't fire in the new life.

## Tuning

Select the `Player` node in `player.tscn` and edit values in the Inspector.

| Group | Value | Default | Effect |
|---|---|---|---|
| Run | `run_speed` | 140 | Top horizontal speed (px/s) |
| Run | `acceleration` | 1200 | How fast the player reaches top speed on the ground |
| Run | `friction` | 1400 | How fast the player stops on the ground |
| Run | `air_acceleration` | 900 | Horizontal control in the air |
| Jump | `jump_height` | 52 | Full jump height (px) |
| Jump | `jump_time_to_peak` | 0.36 | Seconds to reach the top |
| Jump | `jump_time_to_fall` | 0.28 | Seconds to fall the same height |
| Jump | `jump_cut_multiplier` | 0.45 | Upward speed kept when releasing jump early |
| Jump | `max_fall_speed` | 360 | Terminal fall speed (px/s) |
| Jump | `coyote_time` | 0.1 | Grace period after leaving a ledge (s) |
| Jump | `jump_buffer_time` | 0.12 | How early a jump press is remembered (s) |
| Landing | `hard_landing_height` | 160 | Fall distance that ends in a hard landing (px) |
| Landing | `hard_landing_time` | 0.5 | Seconds stuck in place after a hard landing |
| Landing | `hard_landing_dash_cancel` | 0.5 | Fraction of the hard landing after which a dash cancels it |
| Dash | `dash_speed` | 300 | Dash speed (px/s) |
| Dash | `dash_duration` | 0.18 | Dash length (s) |
| Attack | `attack_startup` | 0.05 | Wind-up before the hitbox turns on (s) |
| Attack | `attack_active` | 0.1 | How long the hitbox is on (s) |
| Attack | `attack_recovery` | 0.15 | Time after the hitbox turns off before the player can act (s) |
| Attack | `attack_buffer_time` | 0.12 | How early an attack press is remembered (s) |
| Attack | `attack_vertical_threshold` | 0.75 | Vertical input needed for an up or crouch attack |
Hurt and death values are on the **`Damage`** child node (`PlayerDamage`):

| Group | Value | Default | Effect |
|---|---|---|---|
| Hurt | `hurt_duration` | 0.3 | Seconds without control after a NORMAL hit |
| Hurt | `hurt_knockback` | (160, 140) | Speed away from the hit (x) and upward pop (y), px/s |
| Hurt | `heavy_hurt_duration` | 0.5 | Seconds without control after a HEAVY hit |
| Hurt | `heavy_knockback` | (240, 180) | Knockback for a HEAVY hit, px/s |
| Invincibility | `invincibility_time` | 0.5 | Immunity after Hurt ends (s), or after a LIGHT hit |
| Death | `death_delay` | 1.0 | Seconds before a dead player respawns |

Climbing values are on the **`LadderClimb`** child node (`PlayerLadderClimb`):

| Value | Default | Effect |
|---|---|---|
| `climb_speed` | 80 | Climbing speed up and down (px/s) |
| `grab_reach` | 8 | How far from a ladder's centre the player can grab it (px) |
| `grab_height` | 24 | How far above the feet a ladder can still be grabbed (px); the feet are pulled up onto a ladder that ends above them |
| `grab_threshold` | 0.5 | Vertical input needed to grab a ladder from the ground |
| `air_grab_threshold` | 0.25 | Vertical input needed to grab a ladder in the air |
| `regrab_delay` | 0.5 | Time after letting go (down + jump, or off the bottom) before a ladder can be grabbed again (s). After a jump off, grabbing is blocked until the jump peaks instead |

Ledge values are on the **`LedgeGrab`** child node (`PlayerLedgeGrab`):

| Value | Default | Effect |
|---|---|---|
| `hand_height` | 28 | Hands above the feet (px); the ledge top is held at this height |
| `grab_reach` | 4 | How far in front of the body a wall is still grabbed (px) |
| `snap_window` | 8 | How far above or below the hands a ledge top can be and still be caught (px) |
| `min_drop` | 16 | Air needed under the feet while hanging (px); shorter walls aren't ledges |
| `input_threshold` | 0.5 | Vertical input needed to climb up or drop down |
| `climb_delay` | 0.1 | Hang time before up or jump climbs (s) |
| `climb_rise_time` | 0.15 | Time to pull the body up beside the wall (s) |
| `climb_over_time` | 0.08 | Time to step onto the top (s) |
| `regrab_delay` | 0.25 | Time after dropping off before a ledge can be grabbed again (s) |
| `body` | `../CollisionShape2D` | The body shape, to check there is room on top |

The drop-through value is on the **`DropThrough`** child node (`PlayerDropThrough`):

| Value | Default | Effect |
|---|---|---|
| `drop_through_time` | 0.25 | How long the platforms layer stays off after dropping through (s) |

Healing values are on the **`Flasks`** child node (`PlayerFlasks`):

| Value | Default | Effect |
|---|---|---|
| `drink_time` | 0.5 | Seconds the player stands still while drinking |

Parry and riposte values are on the **`Parry`** child node (`PlayerParry`) and the **`Riposte`** state node, see [Combat](/systems/combat#parry-and-riposte-1).

Maximum health, flask count and heal, damage, resistances, spirit, the parry windows and the dash cooldown are on the **`Stats`** child node (`PlayerStats`), so items and skills can change them. See [Stats](/systems/stats#tuning). Flash, hit-stop and shake are on the `HurtFeedback` node, see [Combat](/systems/combat#hurtfeedback).

## Public helpers

Used by states and other systems:

| Function | Purpose |
|---|---|
| `get_move_axis()` | Horizontal input from -1 to 1 |
| `get_vertical_axis()` | Vertical input from -1 (up) to 1 (down) |
| `set_facing(direction)` | Flips the visuals |
| `apply_gravity(delta)` | Rising or falling gravity, clamped to `max_fall_speed` |
| `move_horizontally(delta, accel, decel)` | Accelerates toward input or slows down |
| `wants_jump()` / `has_coyote_time()` / `consume_jump()` | Jump buffer and coyote logic |
| `set_platforms_enabled(enabled)` | Turns collision with one-way platforms on or off (drop-through, climbing) |
| `ladder_climb.wants_grab_up()` / `wants_grab_down()` | Up over a ladder, or down on its top; stores the ladder for the Climb state |
| `ladder_climb.jump_off()` / `let_go()` | Blocks grabbing until the jump peaks, or for `regrab_delay` |
| `ledge_grab.wants_grab()` | Falling past a ledge the player faces; stores the corner for LedgeHang |
| `ledge_grab.hang_position()` / `stand_position()` | Where the feet go while hanging, and once on top |
| `drop_through.wants()` / `drop_through.start()` | Down + jump on a one-way platform, drop timer (on `PlayerDropThrough`) |
| `wants_dash()` / `start_dash()` | Dash press on the ground, cooldown |
| `wants_attack()` / `consume_attack()` | Attack buffer |
| `parry.wants()` / `parry.play_feedback()` | Parry pressed on the ground; freeze, shake and rumble on a successful parry (on `PlayerParry`) |
| `flasks.wants()` / `flasks.drink()` / `flasks.refill()` | Heal pressed with a flask left and health missing; use one and heal; fill them all (on `PlayerFlasks`) |
| `can_interact()` | Interact just pressed, on the ground, in Idle or Run: used by doors and other [interaction areas](/systems/rooms#interaction-areas) |
| `set_camera_limits(bounds)` | Called by the room |
| `respawn(at)` | Teleports, resets velocity, health, flasks, invincibility, input buffers and camera, enters Idle |

## Known limitations

- Placeholder rectangles instead of sprites and animations.
- Knockback strength comes from the reaction only; hitbox `knockback_force` is ignored for the player.
- No death animation yet.
- No drinking animation or sounds (drinking, empty flask): a placeholder aura stands in for the animation.
- The number of flasks and how much they heal can't be upgraded yet.
- Ledges are found automatically on every wall top that passes the checks; there is no way to turn one off or force one by hand yet (planned as optional ledge markers, see [Roadmap](/roadmap)).
- No hang or climb-up animation for ledges. A ladder caught by the upper body pulls the feet up in one frame (up to `grab_height`).
