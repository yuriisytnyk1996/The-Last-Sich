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
│   └── Eye (ColorRect)      placeholder, shows facing direction
├── Camera2D                 smoothed, limited by the room's bounds
└── StateMachine
    ├── Idle  ├── Run  ├── Jump  ├── Fall  └── Dash
```

## States and transitions

| State | Does | Leaves to |
|---|---|---|
| **Idle** | Gravity, slows to a stop | Fall (not on floor), Jump (jump buffered), Dash, Run (move input) |
| **Run** | Gravity, accelerates toward `run_speed` | Fall, Jump, Dash, Idle (no move input) |
| **Jump** | Sets upward velocity, cuts the jump if the button is released | Dash, Fall (once moving down) |
| **Fall** | Gravity, air control | Jump (coyote time), Dash, Idle/Run (landed) |
| **Dash** | Fixed horizontal speed, no gravity | Idle/Run (on floor), Fall (in air) |

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

## Public helpers

Used by states and other systems:

| Function | Purpose |
|---|---|
| `get_move_axis()` | Horizontal input from -1 to 1 |
| `set_facing(direction)` | Flips the visuals |
| `apply_gravity(delta)` | Rising or falling gravity, clamped to `max_fall_speed` |
| `move_horizontally(delta, accel, decel)` | Accelerates toward input or slows down |
| `wants_jump()` / `has_coyote_time()` / `consume_jump()` | Jump buffer and coyote logic |
| `wants_dash()` / `start_dash()` | Dash availability and cooldown |
| `set_camera_limits(bounds)` | Called by the room |
| `respawn(at)` | Teleports, resets velocity and camera, enters Idle |

## Known limitations

- Placeholder rectangles instead of sprites and animations.
- No attack, health or damage yet.
- No dropping down through one-way platforms.
