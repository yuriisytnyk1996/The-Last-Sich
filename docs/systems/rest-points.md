# Rest points

A rest point is a checkpoint. Pressing up at one heals the player to full, resets the enemies in the room and makes it the place the player comes back to after dying, even from another room.

## How it works

1. A `RestPoint` (`levels/objects/rest_point.gd`, scene `levels/objects/rest_point.tscn`) is an [interaction area](/systems/rooms#interaction-areas) with `press_up` on. The player stands at it and presses up (on the ground, in Idle or Run). A `Prompt` arrow shows while they're in range.
2. The rest point restores the player's health (`Health.reset()`, so the HUD bar refills), stops their horizontal movement, calls `reset()` on every node in the `enemies` group and emits `Events.rested(rest_point)`.
3. Every rest point listens to `Events.rested`: the one that was used lights its flame, the others put theirs out.
4. `World` (`levels/world.gd`) remembers the last rest point used: the scene path of its room and its node path inside that room.
5. When the player dies (`Events.player_died`), `World` checks for a remembered rest point:
   - **None yet:** the current room respawns the player where they entered it, as before (see [Rooms](/systems/rooms#how-it-works)).
   - **One was used:** `World` fades out, reloads the rest point's room (also when it's the current one, so its enemies start fresh), respawns the player on the rest point with full health and fades back in.
6. Whenever a room loads, `World` lights its rest point if it's the remembered one.

Resting doesn't save the game to disk yet. The remembered rest point lasts until the game is closed. That comes with the save system.

## Files

| File | Role |
|---|---|
| `levels/objects/rest_point.gd` | `RestPoint`: heals, resets enemies, emits `Events.rested`, shows whether it's lit |
| `levels/objects/rest_point.tscn` | Area, placeholder post with a crossbar, `Flame` and `Prompt` |
| `levels/world.gd` | Remembers the last rest point used and respawns the player there |
| `autoload/events.gd` | `rested(rest_point)` signal |

## Scene layout

```
RestPoint (Area2D)   layer: none   mask: player   press_up: on
├── Shape            24×40 rectangle, bottom at the origin
├── Visual
│   ├── Post  ├── Bar   placeholder
│   └── Flame           shown while this is the active rest point
└── Prompt (Polygon2D)  shown while the player is in range
```

The origin is the bottom centre and is also where the player respawns: place it on the ground.

## Tuning

A rest point has no values of its own. `press_up` comes from `InteractionArea` and is on in the scene.

## Extending

- Place one by instancing `levels/objects/rest_point.tscn` anywhere in a room, standing on the ground. The test house has one.
- The node path inside the room is what `World` remembers, so renaming or moving a rest point inside its room loses it as a respawn point until it's used again.

## Known limitations

- Not saved to disk yet: closing the game forgets it.
- No resting animation or menu. The player keeps control the whole time.
- Resting resets only the current room's enemies. Other rooms reset anyway when they load.
- Placeholder rectangles for the post and flame.
