# Game feel

Two global effects that make hits feel heavy: a short **hit-stop** (the game freezes for a few frames) and **camera shake**. Both are requested by gameplay code without knowing anything about cameras or the engine clock. Today the only requester is [`HurtFeedback`](/systems/combat#hit-feedback).

## How it works

### Hit-stop

`autoload/hit_stop.gd` is registered as **`HitStop`**.

1. `HitStop.freeze(duration)` sets `Engine.time_scale` to 0. Physics, animations, tweens and timers all stop.
2. The autoload runs with `PROCESS_MODE_ALWAYS` and checks the real clock (`Time.get_ticks_msec()`) every frame.
3. Once `duration` real seconds have passed, `time_scale` goes back to 1.

It checks the real clock because a `SceneTreeTimer`, even with `ignore_time_scale`, never fired while the time scale was 0.

Overlapping freezes don't add up. The one that ends last decides when the game resumes, so two hits in the same frame freeze once.

### Camera shake

`components/camera/camera_shake.gd` (`CameraShake`) is a child of the player's `Camera2D`.

1. Anything emits `Events.camera_shake_requested(trauma)`, where trauma is 0 to 1.
2. `CameraShake` adds it to its current trauma (capped at 1).
3. Every frame the camera's `offset` is set to a random direction × `max_offset` × trauma², rounded to whole pixels. Trauma drains by `decay` per second.

Squaring the trauma means small requests barely move the camera while big ones shake hard, and the shake eases out smoothly instead of stopping abruptly. During a hit-stop the shake holds still, because the frame delta is 0.

## Files

| File | Role |
|---|---|
| `autoload/hit_stop.gd` | `HitStop` autoload: `freeze(duration)` |
| `components/camera/camera_shake.gd` | `CameraShake`: trauma-based offset shake for its parent camera |
| `components/combat/hurt_feedback.gd` | Asks for both on every hit, see [Combat](/systems/combat#hit-feedback) |

## Tuning

### CameraShake

| Value | Default | Effect |
|---|---|---|
| `max_offset` | (8, 5) | Offset at full trauma (px) |
| `decay` | 2.5 | Trauma lost per second |

How long and how hard each hit freezes and shakes is set on each actor's `HurtFeedback` node, scaled by the hit's [reaction](/systems/combat#reactions).

## Extending

**Shake from something other than a hit** (an explosion, a boss landing): `Events.camera_shake_requested.emit(0.8)`.

**Freeze from something else** (a parry, a finishing blow): `HitStop.freeze(0.15)`.

## Known limitations

- Hit-stop freezes everything, including the HUD. If UI animations must keep running, give them `PROCESS_MODE_ALWAYS` and real-time animation.
- No controller rumble yet.
