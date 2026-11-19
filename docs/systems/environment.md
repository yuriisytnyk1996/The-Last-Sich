# Environment

Level pieces that move, break, hurt or change how the player moves: breakable props, moving platforms, crumbling platforms, timed platform sequences, elevators, timed traps, turrets, drip traps, ghost traps (pages that flutter up, for show), shockwave areas, and wind, mud and poison zones. Pieces that lock places behind items (climb walls, reveal platforms, levers, gates, chests, secret walls) are on the [Traversal](/systems/traversal) page. They are placed in rooms like ladders and spikes, and each one is a small script with its own tuning, so a level designer can drop them in without code.

## How it works

Everything lives in `levels/objects/`, grouped by kind. Pieces that change where the player can stand or get hurt go in the room's `Layout` part; pieces that are saved go in `Logic` (see [Room structure](/systems/rooms#room-structure)).

### Breakables

`Breakable` (`levels/objects/breakables/breakable.gd`) is a prop the player breaks with attacks. Its `Hurtbox` masks `player_attacks`, so every swing, finisher and bolt counts. After `hits` hits it hides its `Visual` (or fades it over `fade_time`), stops taking hits, turns off the collision of its optional `Body` and gives `currency` through `Events.currency_earned`. The currency is scaled by the [death penalty](/systems/death-penalty) like an enemy's reward.

- **Crate** (`crate.tscn`): one hit, 5 currency, no collision. It comes back every time the room loads.
- **Cracked wall** (`breakable_wall.tscn`): 16×48, three hits, a `Body` on the `world` layer that blocks the way. `stays_broken` is on, so it joins the `persistent` group and the [save system](/systems/save-system) keeps it broken for good.
- **Secret wall** (`secret_wall.tscn`): looks like the terrain, three hits from one side only, and fades out to show the secret behind it. See [Traversal](/systems/traversal#secret-walls).

`breakable_from` limits hits to one side (`LEFT` or `RIGHT` of the breakable's origin, `BOTH` by default). From the other side the hurtbox is off, so swings pass through without a flash. With `stays_broken`, the hits taken so far are saved too, so a half-broken wall stays half broken.

The hurtbox has `rewards_attacker` off, so hitting props fills no [spirit](/systems/spirit). Otherwise players could charge spirit on a crate.

### Moving platforms

`MovingPlatform` (`levels/objects/platforms/moving_platform.gd`) is an `AnimatableBody2D` that travels from where it is placed to `travel` px away and back, easing in and out and waiting `pause_time` at each end. Godot moves bodies standing on it along with it, so the player and enemies ride it without extra code. It is one-way by default, on the `platforms` layer: jump up through it, drop through it with down + jump. With `one_way` off it is a solid block on the `world` layer. `phase` starts it partway through its trip, so platforms side by side can move out of step.

### Crumbling platforms

`CrumblePlatform` (`levels/objects/platforms/crumble_platform.gd`) gives way under the player. Once the player lands on top of it (it checks the player's last move for a floor contact with itself, so jumping up through a one-way one doesn't count), it shakes for `crumble_delay`, then gives way: its collision turns off and it fades over `vanish_time`. What it looks like decides what it is:

| Setting | Piece |
|---|---|
| `falls` on (default) | **Collapsing platform**: drops `fall_distance` while it fades. A row of them side by side is a collapsing bridge the player has to keep running across |
| `falls` off | **Vanishing platform**: fades in place |

After `return_time` it fades back in and is solid again. It waits while the player's body is where it would come back, so a solid one never traps them. With `return_time` 0 it stays gone until the room loads again. Nothing is saved. Only the player sets it off, not enemies. Two crack lines tell it apart from a plain plank. One-way on the `platforms` layer by default, solid on `world` with `one_way` off. The origin is the top centre, like a moving platform. [Ledge grab](/systems/player#ledge-grab) never grabs it.

### Timed platform sequences

`PlatformSequence` (`levels/objects/platforms/platform_sequence.gd`) shows its `TimedPlatform` children (`timed_platform.gd`) one step after another, on a loop:

1. Each platform has a `step` (0 first). Platforms with the same step show together, so a step can be one platform or a row.
2. Every `step_time` the next step comes up: its platforms fade in over `fade_time` and are solid for `show_time`.
3. For the last `warn_time` of that they blink white, then their collision turns off and they fade out. A player still on one falls.
4. After the last step the loop starts again at step 0. `offset` shifts the loop, so two sequences side by side can run out of step.

With `show_time` longer than `step_time` (the default: 1.6 against 0.8) the next step is already there when one starts to blink, so the player hops along the steps in order and can't wait around. With `show_time` shorter there is a gap with nothing to stand on, which only works if the jump between steps can be made in the air.

One clock in the sequence drives every platform, so steps never drift apart. A platform outside a sequence stays hidden. Only the player matters: nothing checks for enemies. A solid platform (`one_way` off) doesn't turn solid while the player's body is inside it; it does as soon as they leave. Nothing is saved. The editor draws each platform with its step number; in the game they start hidden. One-way on the `platforms` layer by default, like the other platforms, origin at the top centre. [Ledge grab](/systems/player#ledge-grab) never grabs one.

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

### Drip traps

`DripTrap` (`levels/objects/traps/drip/drip_trap.gd`, scene `drip_trap.tscn`) is a spout in the ceiling that drips burning tar. It is a [turret](#turrets) that doesn't shoot:

1. Every `fire_interval` a drop swells under the spout for `warn_time`: the `Warning` bead grows from a third of its size to a full drop (`Turret.warn_fraction()`).
2. The drop lets go. It is a `LiquidDrop` (`liquid_drop.gd`, `liquid_drop.tscn`), an `EnemyProjectile` that starts still and falls with `fall_acceleration` up to `max_fall_speed`.
3. It bursts on the first thing it touches: the player (20 FIRE damage), a wall, the floor or a one-way plank (its mask is `world` and `platforms`). It can't be parried.

A row of spouts with different `offset`s makes a curtain the player times a run through. `trigger_range` (360 px in the scene) keeps a spout quiet while the player is far away. Put the origin on the ceiling's underside and don't rotate it: drops always fall straight down.

### Ghost traps

`GhostTrap` (`levels/objects/traps/ghost/ghost_trap.gd`, scene `ghost_trap.tscn`) is a haunted spot that stirs as the player passes, a zone on the [`AreaEffect`](#zones) base. It does no harm: loose pages lift and flutter around the player's feet, as if blown by something unseen.

1. When the player enters, a burst of one to `max_pages` pages flies up where they stand (`burst_offset` from their feet).
2. While they stay inside, another burst comes every `trigger_interval`, but only once they have moved `move_threshold` px from the last one. Standing still stirs nothing; walking or dashing through leaves a trail of pages.
3. Bursts stay inside the zone sideways: the player's x is clamped to it, so jumping past its edge doesn't throw pages outside it.
4. Each `GhostPage` (`ghost_page.gd`, `ghost_page.tscn`) takes one of three flights at random (up and left, straight up, up and right) at a random pace (`pace_range`). It slows down (`drag`), sways (`sway`, `sway_rate`) and spins on the way, fades out over the last `fade_part` of its flight and goes back to the [pool](/architecture/object-pooling). It touches nothing.

Lay the zone along the floor, a few tiles tall, where the player walks.

### Shockwave areas

`ShockwaveArea` (`levels/objects/traps/shockwave_area.gd`) is a stretch of floor that quakes on a cycle, also on the `AreaEffect` base:

1. Quiet for `off_time`.
2. The ground trembles for `warn_time`: the band flickers.
3. A shockwave runs through it: for `on_time` a HEAVY hit (`damage` 30, knocked up and away from the middle) covers the whole zone. The camera shakes if the player is within `shake_range`.

The zone is the band that hurts, so lay it on the floor about 12 px tall: a player in the air when it strikes is safe, and so is one standing on a plank above it. It is HEAVY, so a player on the [parry guard](/systems/combat#guard-slide) takes it as a guard slide instead. `offset` shifts the cycle, so neighbouring stretches can quake in turn. The hit is built in code on the `hazards` layer and only hurts the player.

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

- **Upper floor** (y 320), left to right: two crates by the entrance, a Sich letter (x 232, see [test content](/systems/story#test-content)), a wind zone blowing left, a 4-tile gap down to the lower floor, a row of three spike traps striking in a wave, the cracked wall with a crate worth 30 behind it, and the elevator with a call lever.
- **Lower floor** (y 672), right to left from the elevator: the lower call lever, a mud pool, two fire traps, a pit (with a `KillZone`) crossed by a sideways moving platform, a poison cloud, and a vertical moving platform that rises through the upper floor's gap back to the top. A turret on the left wall fires along the lower floor while the player is near. An `East` doorway at the bottom of the right wall leads to the [test vault](/systems/traversal#test-vault-layout).

## Test crypt layout

`levels/rooms/test_crypt.tscn` is a 960×360 room west of the [test house](/systems/rooms#test-house-layout), through a `West` opening in the house's left wall (map cell (-5, 0), zone `Crypt`). From the entrance on the east, going west:

- Three drip traps over the corridor (x 776, 816, 856), out of step, then a one-tile step.
- Two shockwave areas side by side (x 480 to 704) that quake in turn, with a one-way plank 3 tiles above the floor to wait on.
- A ghost trap along the floor of the west part of the room (x 96 to 416): pages flutter up as the player walks through.
- The [Duma of the Road Home](/systems/dumas#dumas) at the far west end, so the way back can be tested at once, and the kobza string next to it (x 104) for the kobzar's quest.
- The alms box (x 200) and a captive cage (x 300) in the ghost trap's part of the room, and a `VisitedArea` by the entrance (x 864) that sets `crypt_visited`. See [test content](/systems/story#test-content).

## Files

| File | Role |
|---|---|
| `levels/objects/breakables/breakable.gd` | `Breakable`: breaks after some hits, drops currency, can stay broken (saved) |
| `levels/objects/breakables/crate.tscn` | One-hit crate |
| `levels/objects/breakables/breakable_wall.tscn` | Cracked wall that blocks the way, stays broken |
| `levels/objects/breakables/secret_wall.tscn` | Secret wall drawn like the terrain, see [Traversal](/systems/traversal#secret-walls) |
| `levels/objects/platforms/moving_platform.gd` | `MovingPlatform`: back-and-forth platform, one-way or solid |
| `levels/objects/platforms/crumble_platform.gd` | `CrumblePlatform`: gives way under the player, comes back |
| `levels/objects/platforms/platform_sequence.gd` | `PlatformSequence`: shows its timed platforms step by step on a loop |
| `levels/objects/platforms/timed_platform.gd` | `TimedPlatform`: shown by a sequence at its `step`, blinks before vanishing |
| `levels/objects/platforms/elevator.gd` | `Elevator`: lift between two stops, starts when stood on |
| `levels/objects/platforms/elevator_call.gd`, `.tscn` | `ElevatorCall`: lever that calls an elevator |
| `levels/objects/traps/timed_trap.gd` | `TimedTrap`: off, warning, on cycle |
| `levels/objects/traps/spike_trap.tscn`, `fire_trap.tscn` | The two timed traps |
| `levels/objects/traps/turret.gd`, `turret.tscn` | `Turret`: fires bolts on a timer |
| `levels/objects/traps/turret_bolt.tscn` | The turret's bolt |
| `levels/objects/traps/drip/drip_trap.gd`, `.tscn` | `DripTrap`: ceiling spout, a swelling drop on a timer |
| `levels/objects/traps/drip/liquid_drop.gd`, `.tscn` | `LiquidDrop`: a falling drop that bursts on contact |
| `levels/objects/traps/ghost/ghost_trap.gd`, `.tscn` | `GhostTrap`: haunted zone that blows pages up around the moving player |
| `levels/objects/traps/ghost/ghost_page.gd`, `.tscn` | `GhostPage`: one fluttering page, for show only; pooled |
| `levels/objects/traps/shockwave_area.gd` | `ShockwaveArea`: floor band that quakes on a cycle |
| `levels/objects/zones/area_effect.gd` | `AreaEffect`: base zone, size, tint, player tracking |
| `levels/objects/zones/wind_zone.gd`, `mud_zone.gd`, `poison_zone.gd` | The three zones |
| `actors/player/abilities/area_effects.gd` | `PlayerAreaEffects`: combines the zones the player is in |
| `levels/rooms/test_works.tscn`, `test_works/` | Test room with most pieces |
| `levels/rooms/test_crypt.tscn`, `test_crypt/` | Test room with the drip traps, shockwave areas and ghost trap |

## Tuning

| Value | Script | Default | Effect |
|---|---|---|---|
| `hits` | `Breakable` | 1 | Hits to break it. Cracked wall: 3 |
| `currency` | `Breakable` | 0 | Currency when broken. Crate: 5 |
| `stays_broken` | `Breakable` | false | Saved (hits taken and broken) for good. On for the cracked and secret walls |
| `break_shake` | `Breakable` | 0.15 | Camera trauma on break. Cracked and secret wall: 0.4 |
| `breakable_from` | `Breakable` | `BOTH` | Side the player has to stand on for hits to count. Secret wall: `LEFT` |
| `fade_time` | `Breakable` | 0 | Seconds `Visual` fades when broken; 0 hides it at once. Secret wall: 0.6 |
| `break_sound` | `Breakable` | `break` | [Sound cue](/systems/audio) when it breaks |
| `map_hides` | `Breakable` | empty | A secret: area (px) kept off the [map](/systems/map#secrets) until it breaks. Secret wall: its cover |
| `size` | `MovingPlatform` | 48×8 | Platform size (px) |
| `travel` | `MovingPlatform` | (128, 0) | Far end, from the start (px) |
| `speed` | `MovingPlatform` | 50 | px/s, eased at the ends |
| `pause_time` | `MovingPlatform` | 0.6 | Wait at each end (s) |
| `phase` | `MovingPlatform` | 0 | Start point in the round trip (0 to 1) |
| `one_way` | `MovingPlatform` | true | One-way on `platforms`, or solid on `world` |
| `safe_ground` | `MovingPlatform` | false | Death marks may land on it while it waits at an end ([safe ground](/systems/death-penalty#safe-ground)) |
| `size` | `CrumblePlatform` | 32×8 | Platform size (px) |
| `one_way` | `CrumblePlatform` | true | One-way on `platforms`, or solid on `world` |
| `crumble_delay` | `CrumblePlatform` | 0.5 | Shaking under the player before it gives way (s) |
| `falls` | `CrumblePlatform` | true | Drops while fading (collapsing); off fades in place (vanishing) |
| `fall_distance` | `CrumblePlatform` | 24 | How far it drops (px) |
| `vanish_time` | `CrumblePlatform` | 0.3 | Fade out, and fade back in (s) |
| `return_time` | `CrumblePlatform` | 3 | Seconds until it comes back. 0: until the room loads again. Test shaft bridge: 0 |
| `shake_amount` | `CrumblePlatform` | 1 | Sideways shake while crumbling (px) |
| `step_time` | `PlatformSequence` | 0.8 | Seconds between one step and the next |
| `show_time` | `PlatformSequence` | 1.6 | Seconds each step stays, warning included |
| `warn_time` | `PlatformSequence` | 0.4 | Seconds a step blinks before it vanishes |
| `fade_time` | `PlatformSequence` | 0.15 | Fade in and out (s) |
| `offset` | `PlatformSequence` | 0 | Loop shift (s) |
| `size` | `TimedPlatform` | 32×8 | Platform size (px) |
| `one_way` | `TimedPlatform` | true | One-way on `platforms`, or solid on `world` |
| `step` | `TimedPlatform` | 0 | When in the sequence it shows. Same step, same time |
| `size` | `Elevator` | 48×8 | Platform size (px) |
| `travel` | `Elevator` | (0, 192) | Second stop, from the first (px) |
| `speed` | `Elevator` | 80 | px/s |
| `start_delay` | `Elevator` | 0.4 | Seconds stood on before it starts |
| `safe_ground` | `Elevator` | false | Death marks may land on it while it waits at a stop ([safe ground](/systems/death-penalty#safe-ground)) |
| `off_time` | `TimedTrap` | 1.4 | Off part of the cycle (s). Fire trap: 1.6 |
| `warn_time` | `TimedTrap` | 0.5 | Warning before striking (s). Fire trap: 0.6 |
| `on_time` | `TimedTrap` | 0.8 | Hitbox active (s). Fire trap: 1.0 |
| `offset` | `TimedTrap` | 0 | Cycle shift (s) |
| `fire_interval` | `Turret` | 2.0 | Seconds between shots |
| `warn_time` | `Turret` | 0.4 | Warning before a shot (s) |
| `offset` | `Turret` | 0 | Cycle shift (s) |
| `trigger_range` | `Turret` | 0 | Fires only while the player is this close (px). 0: always |
| `speed`, `lifetime` | turret bolt | 160, 3.0 | Bolt speed (px/s) and life (s) |
| `fire_interval` | drip trap | 1.6 | Seconds between drops |
| `warn_time` | drip trap | 0.7 | Seconds a drop swells before it falls |
| `trigger_range` | drip trap | 360 | Drips only while the player is this close (px) |
| `fall_acceleration` | `LiquidDrop` | 700 | Gravity on the drop (px/s²) |
| `max_fall_speed` | `LiquidDrop` | 380 | Fastest fall (px/s) |
| `damage`, `lifetime` | liquid drop | 20 (FIRE), 3.0 | Damage and life (s) |
| `page_scene` | `GhostTrap` | `ghost_page.tscn` | The page it blows up |
| `max_pages` | `GhostTrap` | 3 | Most pages in one burst (one to this many, at random) |
| `burst_offset` | `GhostTrap` | (0, -4) | Burst point, from the player's feet (px) |
| `trigger_interval` | `GhostTrap` | 0.1 | Seconds between bursts while the player moves |
| `move_threshold` | `GhostTrap` | 10 | Distance moved for the next burst (px) |
| `flight_time` | `GhostPage` | 1.0 | Seconds a flight lasts at full pace |
| `pace_range` | `GhostPage` | (0.5, 1.0) | Slowest and fastest pace; the flight lasts `flight_time` / pace |
| `sway`, `sway_rate` | `GhostPage` | 6, 2.5 | Sideways sway (px) and sways per second |
| `spin` | `GhostPage` | 6 | Fastest spin (radians/s) |
| `drag` | `GhostPage` | 1.2 | Fraction of speed lost per second |
| `fade_part` | `GhostPage` | 0.4 | Part of the flight, at the end, spent fading |
| `off_time` | `ShockwaveArea` | 1.8 | Quiet part of the cycle (s) |
| `warn_time` | `ShockwaveArea` | 0.7 | Trembling before the strike (s) |
| `on_time` | `ShockwaveArea` | 0.2 | Hit active (s) |
| `offset` | `ShockwaveArea` | 0 | Cycle shift (s). Test crypt east band: 1.35 |
| `damage` | `ShockwaveArea` | 30 | HEAVY damage |
| `knockback_force` | `ShockwaveArea` | 180 | Knockback, up and away from the middle |
| `shake` | `ShockwaveArea` | 0.3 | Camera trauma on a strike near the player |
| `shake_range` | `ShockwaveArea` | 160 | Distance from the zone for the shake (px) |
| `size` | `AreaEffect` | 64×64 | Zone size (px) |
| `strength` | `WindZone` | 60 | Push (px/s), positive blows right |
| `speed_multiplier` | `MudZone` | 0.5 | Fraction of run speed kept |
| `jump_multiplier` | `MudZone` | 0.5 | Fraction of jump height kept |
| `damage` | `PoisonZone` | 20 | Damage per tick (POISON element) |
| `tick_time` | `PoisonZone` | 1.2 | Seconds between ticks |
| `grace_time` | `PoisonZone` | 0.6 | Seconds inside before the first tick |

## Extending

- **A new breakable:** make a scene with a `Breakable` root, a `Visual`, a `Hurtbox` (mask `player_attacks`, `rewards_attacker` off) and optionally a `Body`. Put it in `Logic` if it stays broken, since saved node paths live there.
- **A new timed trap:** a `TimedTrap` scene with a `Warning` (any `CanvasItem`) and a `Hitbox` on the `hazards` layer with `continuous` on. Visuals under the hitbox show only while it is active.
- **A timed climb:** add a `PlatformSequence` to the room's `Layout`, put `TimedPlatform`s under it and number their `step`s in the order the player should take them. Keep each hop inside the player's jump (52 px up) and give the step after a hop enough `show_time` overlap to land.
- **A drip curtain:** a row of `drip_trap.tscn` on the ceiling, 32 to 48 px apart, with `offset`s spread over `fire_interval`.
- **Something else stirred up** (ash, leaves, feathers): a scene with a `GhostPage` root and its own look, set as the trap's `page_scene`.
- **A new zone:** extend `AreaEffect` with `@tool`, override `_get_color()` and the factors it changes (`speed_factor()`, `jump_factor()`, `wind_speed()`), or use `_player_entered()` / `_player_exited()` for timed effects like poison. If it needs a new kind of factor, add it to `AreaEffect` and `PlayerAreaEffects` and read it where the player moves.

## Known limitations

- All placeholder art: flat rectangles, drawn tints and streaks. No break debris, no splashes for drops, no sounds.
- Ghost traps only react to the player, not to enemies, and have no sound yet.
- Shockwave areas and drip traps always run, even with the player far away (drips just don't fall).
- Zones don't affect enemies.
- Wind only blows sideways; there are no updrafts.
- A platform or elevator moving down onto a player standing on the ground under it pushes them into the floor. Leave room under their paths.
- Elevator positions aren't saved.
- Timed platform sequences always run, even when the player is far away, and can't be started or stopped by a lever or a fight.
- Crumbling platforms only react to the player, and a collapsed bridge can't be crossed again until the room reloads, so don't make one the only way back.
