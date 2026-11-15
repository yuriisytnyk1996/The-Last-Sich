# Player

The player is a `CharacterBody2D` driven by a [state machine](/architecture/state-machine).

## Files

| File | Role |
|---|---|
| `actors/player/player.tscn` | Scene: body, collision, visuals, camera, state machine |
| `actors/player/player.gd` | `Player`: tuning values, timers and helper functions shared by states |
| `actors/player/states/player_state.gd` | `PlayerState`: base class with a typed `player` reference and state name constants |
| `actors/player/states/*.gd` | One script per state |

## Scene tree

```
Player (CharacterBody2D)     layer: player   mask: world   group: "player"
├── CollisionShape2D         12×30 rectangle, origin at the feet
├── Visual (Node2D)          flipped with scale.x to face left/right
│   ├── Body (ColorRect)     placeholder
│   ├── Eye (ColorRect)      placeholder, shows facing direction
│   └── Attacks (Node2D)     one Hitbox per attack, layer: player_attacks
│       ├── Side  ├── Up  └── Crouch   each with a Shape and a placeholder Slash
├── Health                   5 hit points
├── Hurtbox (Area2D)         10×26, mask: enemy_attacks, hazards
├── InvincibilityBlink       blinks Visual while the hurtbox is invincible
├── Camera2D                 smoothed, limited by the room's bounds
└── StateMachine
    ├── Idle  ├── Run  ├── Jump  ├── Fall  ├── Dash
    ├── SideAttack  ├── UpAttack  ├── CrouchAttack
    └── Hurt  └── Dead
```

## States and transitions

| State | Does | Leaves to |
|---|---|---|
| **Idle** | Gravity, slows to a stop | Fall (not on floor), Jump (jump buffered), Dash, an attack (attack buffered), Run (move input) |
| **Run** | Gravity, accelerates toward `run_speed` | Fall, Jump, Dash, an attack, Idle (no move input) |
| **Jump** | Sets upward velocity, cuts the jump if the button is released | Dash, an attack, Fall (once moving down) |
| **Fall** | Gravity, air control | Jump (coyote time), Dash, an attack, Idle/Run (landed) |
| **Dash** | Fixed horizontal speed, no gravity | Idle/Run (on floor), Fall (in air) |
| **SideAttack / UpAttack / CrouchAttack** | One swing: startup, active (hitbox on), recovery. The direction comes from the vertical input when attack is pressed. See [Combat](/systems/combat#player-attacks) | Idle/Run (on floor), Fall (in air), another attack (re-swing after a miss) |
| **Hurt** | Entered from any state when the hurtbox takes a hit. Knocked up and away, faces the hit, no control | Idle/Run (on floor), Fall (in air) after `hurt_duration` |
| **Dead** | Entered from any state when health reaches 0. Dark tint, keeps its knockback and slides to a stop | None: emits `Events.player_died` after `death_delay`, and the room's respawn puts the player in Idle |

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

### Dash

A fixed-speed horizontal burst in the input direction (or facing direction if there's no input). One air dash is allowed until the player lands. The cooldown prevents spamming.

### Taking damage

1. A `Hitbox` on `enemy_attacks` or `hazards` touches the player's `Hurtbox`.
2. The hurtbox starts `invincibility_time` and emits `hurt`. `Player` works out `hurt_direction` and enters **Hurt**.
3. The hurtbox removes health. At 0, `Health.died` makes `Player` enter **Dead** instead.

**Knockback direction:** the horizontal sign of the hitbox's knockback. A hitbox that pushes straight up (spikes) pushes the player away from its centre. If the player is exactly on the centre, they are pushed backwards.

**Invincibility** counts from the hit and lasts longer than `hurt_duration`, so the player gets control back while still safe for a moment. The `InvincibilityBlink` node shows it by blinking `Visual`. While invincible, new hits are ignored completely: no damage, no knockback.

**Respawn** (`respawn(at)`) restores full health and ends invincibility.

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
| Dash | `dash_speed` | 300 | Dash speed (px/s) |
| Dash | `dash_duration` | 0.18 | Dash length (s) |
| Dash | `dash_cooldown` | 0.4 | Time before the next dash (s) |
| Attack | `attack_startup` | 0.05 | Wind-up before the hitbox turns on (s) |
| Attack | `attack_active` | 0.1 | How long the hitbox is on (s) |
| Attack | `attack_recovery` | 0.15 | Time after the hitbox turns off before the player can act (s) |
| Attack | `attack_buffer_time` | 0.12 | How early an attack press is remembered (s) |
| Attack | `attack_vertical_threshold` | 0.75 | Vertical input needed for an up or crouch attack |
| Hurt | `hurt_duration` | 0.3 | Seconds without control after a hit |
| Hurt | `hurt_knockback` | (160, 140) | Speed away from the hit (x) and upward pop (y), px/s |
| Hurt | `invincibility_time` | 1.0 | Immunity after a hit (s), counted from the hit. Copied to the `Hurtbox` on ready |
| Hurt | `death_delay` | 1.0 | Seconds before the room respawns a dead player |

Maximum health is set on the `Health` child node (`max_health`, default 5).

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
| `wants_dash()` / `start_dash()` | Dash availability and cooldown |
| `wants_attack()` / `consume_attack()` | Attack buffer |
| `set_camera_limits(bounds)` | Called by the room |
| `respawn(at)` | Teleports, resets velocity, health, invincibility and camera, enters Idle |

## Known limitations

- Placeholder rectangles instead of sprites and animations.
- Health is only shown in the debug label until the HUD exists.
- Every hit uses the same knockback; hitbox `knockback_force` is ignored for the player.
- No hit-stop, screen shake or death animation yet.
- No combos or movement attacks yet (planned as upgrades).
- No dropping down through one-way platforms.
