# Environment

Level pieces that move, break, hurt or change how the player moves: breakable props, moving platforms, elevators, timed traps, turrets, and wind, mud and poison zones. They are placed in rooms like ladders and spikes, and each one is a small script with its own tuning, so a level designer can drop them in without code.

## How it works

Everything lives in `levels/objects/`, grouped by kind. Pieces that change where the player can stand or get hurt go in the room's `Layout` part; pieces that are saved go in `Logic` (see [Room structure](/systems/rooms#room-structure)).

### Breakables

`Breakable` (`levels/objects/breakables/breakable.gd`) is a prop the player breaks with attacks. Its `Hurtbox` masks `player_attacks`, so every swing, finisher and bolt counts. After `hits` hits it hides its `Visual`, stops taking hits, turns off the collision of its optional `Body` and gives `currency` through `Events.currency_earned`. The currency is scaled by the [death penalty](/systems/death-penalty) like an enemy's reward.

- **Crate** (`crate.tscn`): one hit, 5 currency, no collision. It comes back every time the room loads.
- **Cracked wall** (`breakable_wall.tscn`): 16×48, three hits, a `Body` on the `world` layer that blocks the way. `stays_broken` is on, so it joins the `persistent` group and the [save system](/systems/save-system) keeps it broken for good.

The hurtbox has `rewards_attacker` off, so hitting props fills no [spirit](/systems/spirit). Otherwise players could charge spirit on a crate.

### Moving platforms

`MovingPlatform` (`levels/objects/platforms/moving_platform.gd`) is an `AnimatableBody2D` that travels from where it is placed to `travel` px away and back, easing in and out and waiting `pause_time` at each end. Godot moves bodies standing on it along with it, so the player and enemies ride it without extra code. It is one-way by default, on the `platforms` layer: jump up through it, drop through it with down + jump. With `one_way` off it is a solid block on the `world` layer. `phase` starts it partway through its trip, so platforms side by side can move out of step.

### Elevators

`Elevator` (`levels/objects/platforms/elevator.gd`) is a solid lift between two stops: where it is placed and `travel` px away.

1. When the player stands on it (a slide collision with it while on the floor) for `start_delay`, it moves to the other stop at `speed`.
2. At the stop it waits. It won't start again until the rider has stepped off, so standing still doesn't send it back.
3. An `ElevatorCall` lever (`elevator_call.tscn`, an [interaction area](/systems/rooms#interaction-areas)) next to a stop calls it: press interact and the elevator goes to the stop nearest the lever. Put a lever at every stop, or a player who rode it away can get stuck.

Sink each stop into the floor by the elevator's thickness, so its top is level with the ground. Its position isn't saved: it is back at the first stop each time the room loads.

### Timed traps

`TimedTrap` (`levels/objects/traps/timed_trap.gd`) strikes on a fixed cycle: off for `off_time`, its `Warning` child shows for `warn_time`, then its `Hitbox` is active for `on_time`. The hitbox is on the `hazards` layer and `continuous`, so standing in it keeps hurting. Unlike [spikes](/systems/combat#spikes) it deals normal damage instead of killing. `offset` shifts the cycle, so a row of traps can strike in a wave.

- **Spike trap** (`spike_trap.tscn`): 32 px wide, spikes shoot 16 px out of the floor.
- **Fire trap** (`fire_trap.tscn`): a nozzle and a 52 px fire jet, with longer on and off times. Rotate it to fire from a wall or the ceiling.

### Turrets

`Turret` (`levels/objects/traps/turret.gd`) fires a bolt along its local +x every `fire_interval`. Its `Warning` shows `warn_time` before each shot. The bolt (`turret_bolt.tscn`) is an `EnemyProjectile` (see [Enemies](/systems/enemies)): it stops at walls, can't be parried, and the turret itself can't be destroyed. With `trigger_range` above 0 it only fires while the player is that close.

### Zones

`AreaEffect` (`levels/objects/zones/area_effect.gd`) is the base of every zone. The origin is the top left corner, `size` sets the area (the collision shape is built from it at runtime), and it draws a placeholder tint, also in the editor. When the player enters, it registers with `PlayerAreaEffects` (`actors/player/abilities/area_effects.gd`), which combines every zone the player is in:

| Zone | Effect |
|---|---|
| `WindZone` | `strength` is added to the speed the player runs or drifts at, on the ground and in the air (`Player.move_horizontally()`). Against it, running is slower; letting go carries the player along. Dashes, ladders and ledges ignore it |
| `MudZone` | Run speed times `speed_multiplier`, jump height times `jump_multiplier` (`Player.get_jump_velocity()`). Lay it on the floor, 16 to 24 px tall |
| `PoisonZone` | After `grace_time` inside, a light hit (flash, no stagger) every `tick_time`, from a `Hitbox` the zone builds on the `hazards` layer. It goes through the normal hurt path: invincibility, HUD and death work as usual |

Zones only affect the player. Enemies walk through them unchanged.

## Test works layout

`levels/rooms/test_works.tscn` is a 1280×720 room east of the [test cave](/systems/rooms#test-cave-layout), through a new `East` exit in the cave's right wall. It has two floors:

- **Upper floor** (y 320), left to right: two crates by the entrance, a wind zone blowing left, a 4-tile gap down to the lower floor, a row of three spike traps striking in a wave, the cracked wall with a crate worth 30 behind it, and the elevator with a call lever.
- **Lower floor** (y 672), right to left from the elevator: the lower call lever, a mud pool, two fire traps, a pit (with a `KillZone`) crossed by a sideways moving platform, a poison cloud, and a vertical moving platform that rises through the upper floor's gap back to the top. A turret on the left wall fires along the lower floor while the player is near.

## Files

| File | Role |
|---|---|
| `levels/objects/breakables/breakable.gd` | `Breakable`: breaks after some hits, drops currency, can stay broken (saved) |
| `levels/objects/breakables/crate.tscn` | One-hit crate |
| `levels/objects/breakables/breakable_wall.tscn` | Cracked wall that blocks the way, stays broken |
| `levels/objects/platforms/moving_platform.gd` | `MovingPlatform`: back-and-forth platform, one-way or solid |
| `levels/objects/platforms/elevator.gd` | `Elevator`: lift between two stops, starts when stood on |
| `levels/objects/platforms/elevator_call.gd`, `.tscn` | `ElevatorCall`: lever that calls an elevator |
| `levels/objects/traps/timed_trap.gd` | `TimedTrap`: off, warning, on cycle |
| `levels/objects/traps/spike_trap.tscn`, `fire_trap.tscn` | The two timed traps |
| `levels/objects/traps/turret.gd`, `turret.tscn` | `Turret`: fires bolts on a timer |
| `levels/objects/traps/turret_bolt.tscn` | The turret's bolt |
| `levels/objects/zones/area_effect.gd` | `AreaEffect`: base zone, size, tint, player tracking |
| `levels/objects/zones/wind_zone.gd`, `mud_zone.gd`, `poison_zone.gd` | The three zones |
| `actors/player/abilities/area_effects.gd` | `PlayerAreaEffects`: combines the zones the player is in |
| `levels/rooms/test_works.tscn`, `test_works/` | Test room with every piece |

## Tuning

| Value | Script | Default | Effect |
|---|---|---|---|
| `hits` | `Breakable` | 1 | Hits to break it. Cracked wall: 3 |
| `currency` | `Breakable` | 0 | Currency when broken. Crate: 5 |
| `stays_broken` | `Breakable` | false | Saved and broken for good. On for the cracked wall |
| `break_shake` | `Breakable` | 0.15 | Camera trauma on break. Cracked wall: 0.4 |
| `size` | `MovingPlatform` | 48×8 | Platform size (px) |
| `travel` | `MovingPlatform` | (128, 0) | Far end, from the start (px) |
| `speed` | `MovingPlatform` | 50 | px/s, eased at the ends |
| `pause_time` | `MovingPlatform` | 0.6 | Wait at each end (s) |
| `phase` | `MovingPlatform` | 0 | Start point in the round trip (0 to 1) |
| `one_way` | `MovingPlatform` | true | One-way on `platforms`, or solid on `world` |
| `size` | `Elevator` | 48×8 | Platform size (px) |
| `travel` | `Elevator` | (0, 192) | Second stop, from the first (px) |
| `speed` | `Elevator` | 80 | px/s |
| `start_delay` | `Elevator` | 0.4 | Seconds stood on before it starts |
| `off_time` | `TimedTrap` | 1.4 | Off part of the cycle (s). Fire trap: 1.6 |
| `warn_time` | `TimedTrap` | 0.5 | Warning before striking (s). Fire trap: 0.6 |
| `on_time` | `TimedTrap` | 0.8 | Hitbox active (s). Fire trap: 1.0 |
| `offset` | `TimedTrap` | 0 | Cycle shift (s) |
| `fire_interval` | `Turret` | 2.0 | Seconds between shots |
| `warn_time` | `Turret` | 0.4 | Warning before a shot (s) |
| `offset` | `Turret` | 0 | Cycle shift (s) |
| `trigger_range` | `Turret` | 0 | Fires only while the player is this close (px). 0: always |
| `speed`, `lifetime` | turret bolt | 160, 3.0 | Bolt speed (px/s) and life (s) |
| `size` | `AreaEffect` | 64×64 | Zone size (px) |
| `strength` | `WindZone` | 60 | Push (px/s), positive blows right |
| `speed_multiplier` | `MudZone` | 0.5 | Fraction of run speed kept |
| `jump_multiplier` | `MudZone` | 0.5 | Fraction of jump height kept |
| `damage` | `PoisonZone` | 1 | Damage per tick |
| `tick_time` | `PoisonZone` | 1.2 | Seconds between ticks |
| `grace_time` | `PoisonZone` | 0.6 | Seconds inside before the first tick |

## Extending

- **A new breakable:** make a scene with a `Breakable` root, a `Visual`, a `Hurtbox` (mask `player_attacks`, `rewards_attacker` off) and optionally a `Body`. Put it in `Logic` if it stays broken, since saved node paths live there.
- **A new timed trap:** a `TimedTrap` scene with a `Warning` (any `CanvasItem`) and a `Hitbox` on the `hazards` layer with `continuous` on. Visuals under the hitbox show only while it is active.
- **A new zone:** extend `AreaEffect` with `@tool`, override `_get_color()` and the factors it changes (`speed_factor()`, `jump_factor()`, `wind_speed()`), or use `_player_entered()` / `_player_exited()` for timed effects like poison. If it needs a new kind of factor, add it to `AreaEffect` and `PlayerAreaEffects` and read it where the player moves.

## Known limitations

- All placeholder art: flat rectangles, drawn tints and streaks. No break debris, no sounds.
- Zones don't affect enemies.
- Wind only blows sideways; there are no updrafts.
- A platform or elevator moving down onto a player standing on the ground under it pushes them into the floor. Leave room under their paths.
- Elevator positions aren't saved.
