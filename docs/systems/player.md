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
| `actors/player/states/player_state.gd` | `PlayerState`: base class with a typed `player` reference and state name constants |
| `actors/player/states/*.gd` | One script per state |

## Scene tree

```
Player (CharacterBody2D)     layer: player   mask: world, platforms   group: "player"
├── CollisionShape2D         12×30 rectangle, origin at the feet
├── Visual (Node2D)          flipped with scale.x to face left/right
│   ├── Body (ColorRect)     placeholder
│   ├── Eye (ColorRect)      placeholder, shows facing direction
│   └── Attacks (Node2D)     one Hitbox per attack, layer: player_attacks
│       ├── Side  ├── Up  └── Crouch   each with a Shape and a placeholder Slash
├── Health                   5 hit points
├── Hurtbox (Area2D)         10×26, mask: enemy_attacks, hazards
├── InvincibilityBlink       blinks Visual while the hurtbox is invincible
├── Damage                   PlayerDamage: hit reactions and hurt/death tuning
├── HurtFeedback             flash, hit-stop 0.1 s, shake 0.6
├── DropThrough              PlayerDropThrough: down + jump through one-way platforms
├── LadderClimb              PlayerLadderClimb: finds ladders, climbing tuning
├── Camera2D                 smoothed, limited by the room's bounds
│   └── CameraShake          shakes on Events.camera_shake_requested
└── StateMachine
    ├── Idle  ├── Run  ├── Jump  ├── Fall  ├── Dash  ├── Climb  ├── HardLanding
    ├── SideAttack  ├── UpAttack  ├── CrouchAttack
    └── Hurt  └── Dead
```

## States and transitions

| State | Does | Leaves to |
|---|---|---|
| **Idle** | Gravity, slows to a stop | Fall (not on floor, or dropping through a platform), Climb (up at a ladder, or down on top of one), Jump (jump buffered), Dash, an attack (attack buffered), Run (move input) |
| **Run** | Gravity, accelerates toward `run_speed` | Fall (also when dropping through a platform), Climb, Jump, Dash, an attack, Idle (no move input) |
| **Jump** | Sets upward velocity, cuts the jump if the button is released | Climb (up at a ladder), Dash, an attack, Fall (once moving down) |
| **Fall** | Gravity, air control | Jump (coyote time), Climb (up at a ladder), Dash, an attack, Idle/Run (landed), HardLanding (landed after a long fall) |
| **Dash** | Fixed horizontal speed, no gravity | Idle/Run (on floor), Fall (in air) |
| **Climb** | On a ladder: up and down move along it, no gravity, no attacks, one-way platforms off. See [Climbing ladders](#climbing-ladders) | Idle (reached the top or the ground), Jump (jump, straight up or to the side held), Fall (down + jump, or off the bottom) |
| **HardLanding** | Landed after falling `hard_landing_height` or more: stuck in place for `hard_landing_time`, camera shake. See [Hard landing](#hard-landing) | Idle/Run (time is up), Dash (in the second half), Fall (ground gone) |
| **SideAttack / UpAttack / CrouchAttack** | One swing: startup, active (hitbox on), recovery. The direction comes from the vertical input when attack is pressed. See [Combat](/systems/combat#player-attacks) | Idle/Run (on floor), Fall (in air), another attack (re-swing after a miss) |
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

A [ladder](/systems/rooms#ladders) is grabbed by holding up over it (on the ground or in the air), or by holding down while standing on its top. "Over it" means within `grab_reach` of its centre, with the feet between its top and bottom; grabbing up also needs the ladder to go on above the feet. The player snaps to the ladder's centre and enters **Climb**.

- **Up / down** move at `climb_speed`. With no input the player hangs still.
- **Reaching the top** puts the feet exactly on the ladder's top, on the plank there, and enters Idle. **Reaching the ground** while climbing down enters Idle. **Going past the bottom** of a ladder that hangs in the air lets go (Fall).
- **Jump** is a full jump off the ladder: straight up, or sideways at `run_speed` if a direction is held. Holding up while jumping still jumps. **Down + jump** just lets go and falls. Either way the ladder can't be grabbed again for `regrab_delay`, so holding up doesn't snap you straight back on; after that, holding up over the ladder grabs it again.
- One-way platforms are off while climbing (`set_platforms_enabled(false)`), so the player passes through the plank at the top and any planks the ladder crosses.
- A hit knocks the player off into Hurt as usual.

Ladders can continue into another room through a [vertical exit](/systems/rooms#vertical-exits). The Climb state keeps going after the room changes: its ladder was freed with the old room, so it looks up the ladder at the new position (`PlayerLadderClimb.refind()`) and carries on. Ladders are found by position through the `ladders` group, not by physics, so this works on the very first frame of the new room.

### Hard landing

The **Fall** state measures how far the player drops while moving down. Landing after `hard_landing_height` (160 px, 10 tiles) or more enters **HardLanding** instead of Idle/Run:

- The player can't move for `hard_landing_time` (0.5 s). Horizontal speed is held at 0 and no input is read.
- The camera shakes once (`Events.camera_shake_requested`, trauma 0.5).
- Once `hard_landing_dash_cancel` (half) of the time has passed, a dash gets the player out early.

The distance is counted from where the Fall state starts: the top of a jump, walking off a ledge, letting go of a ladder. It carries through room transitions, so falling through a hole into the room below counts as one drop. Air attacks and dashes start a new count. Ordinary jumps (52 px) and the 2-tile platform rules never come close.

### Dash

A fixed-speed horizontal burst in the input direction (or facing direction if there's no input). One air dash is allowed until the player lands. The cooldown prevents spamming.

### Taking damage

1. A `Hitbox` on `enemy_attacks` or `hazards` touches the player's `Hurtbox`.
2. The hurtbox emits `hurt`. `HurtFeedback` flashes the player, freezes the game and shakes the camera.
3. `PlayerDamage` reads the hit's [reaction](/systems/combat#reactions). LIGHT stops here. NORMAL and HEAVY pick the knockback and stagger time, turn the player to face the hit and enter **Hurt**.
4. The hurtbox removes health. At 0, `Health.died` makes `PlayerDamage` enter **Dead** instead.

`PlayerDamage` also forwards every health change to `Events.player_health_changed`, which drives the [HUD](/systems/hud) health bar.

**Knockback direction:** the horizontal sign of the hitbox's knockback. A hitbox that pushes straight up (spikes) pushes the player away from its centre. If the player is exactly on the centre, they are pushed backwards.

**Invincibility** lasts through the whole Hurt state and for `invincibility_time` after it ends, so the player gets control back while still safe for a moment. A stagger that is longer (heavy hit) automatically gets longer protection. A LIGHT hit, which has no stagger, gives `invincibility_time` from the hit. The `InvincibilityBlink` node shows it by blinking `Visual`. While invincible, new hits are ignored completely: no damage, no knockback.

**Respawn** (`respawn(at)`) restores full health, ends invincibility and clears the jump and attack buffers, so presses made while dead don't fire in the new life.

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
| Dash | `dash_cooldown` | 0.4 | Time before the next dash (s) |
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
| `grab_threshold` | 0.5 | Vertical input needed to grab a ladder |
| `regrab_delay` | 0.5 | Time after jumping off or letting go before a ladder can be grabbed again (s) |

The drop-through value is on the **`DropThrough`** child node (`PlayerDropThrough`):

| Value | Default | Effect |
|---|---|---|
| `drop_through_time` | 0.25 | How long the platforms layer stays off after dropping through (s) |

Maximum health is set on the `Health` child node (`max_health`, default 5). Flash, hit-stop and shake are on the `HurtFeedback` node, see [Combat](/systems/combat#hurtfeedback).

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
| `drop_through.wants()` / `drop_through.start()` | Down + jump on a one-way platform, drop timer (on `PlayerDropThrough`) |
| `wants_dash()` / `start_dash()` | Dash availability and cooldown |
| `wants_attack()` / `consume_attack()` | Attack buffer |
| `can_interact()` | Up just pressed, on the ground, in Idle or Run: used by doors and other [interaction areas](/systems/rooms#interaction-areas) |
| `set_camera_limits(bounds)` | Called by the room |
| `respawn(at)` | Teleports, resets velocity, health, invincibility, input buffers and camera, enters Idle |

## Known limitations

- Placeholder rectangles instead of sprites and animations.
- Knockback strength comes from the reaction only; hitbox `knockback_force` is ignored for the player.
- No death animation yet.
- No combos or movement attacks yet (planned as upgrades).
