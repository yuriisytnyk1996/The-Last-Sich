# Rooms

A room is one playable area of the world. `levels/room.gd` (`Room`) provides the shared logic. `levels/test_room.tscn` is the current test level and the main scene.

## What a room does

1. Places the player at `SpawnPoint` when the room loads.
2. Limits the player's camera to `bounds`, so nothing outside the room is ever shown.
3. Kills the player instantly when they enter `KillZone` (a bottomless pit), whatever health is left, with `Health.kill()`. The player goes through the normal death: the **Dead** state, the HUD bar empties, and after `death_delay` the Dead state emits `Events.player_died`. Invincibility doesn't protect against pits.
4. Respawns the player at `SpawnPoint` when `Events.player_died` fires. `Player.respawn()` restores full health.

## Required nodes

| Node | Type | Purpose |
|---|---|---|
| `SpawnPoint` | `Marker2D` | Where the player appears and respawns |
| `KillZone` | `Area2D` (layer `hazards`, mask `player`) | Bottomless pit: kills the player on contact, ignoring health |
| `Player` | Instance of `player.tscn` | The player |

## Settings

| Value | Default | Effect |
|---|---|---|
| `bounds` | `Rect2i(0, 0, 1280, 360)` | Playable area and camera limits (px) |

## Test room layout

The test room is 1280×360 (two screens wide). It contains:

- Ground on both sides of a gap, with a kill zone in the gap
- Walls at both edges
- Ledges at several heights to test jump height
- A one-way bridge (lighter colour) you can jump up through from below
- A step block on the right side
- Spikes (red) on the right ground, under `Hazards`: a continuous `Hitbox` on the `hazards` layer that deals 1 damage. See [Combat](/systems/combat#hazards)

Platforms are `StaticBody2D` nodes on the `world` layer, each with a `ColorRect` placeholder.

## Making a new room

1. Create a new scene with a `Node2D` root and attach `levels/room.gd`.
2. Add `SpawnPoint`, `KillZone` and an instance of `player.tscn`.
3. Build platforms as `StaticBody2D` children (later: a `TileMapLayer`).
4. Set `bounds` to the room's size.

## Planned

- Split rooms into **Layout** (collision), **Deco** (art and parallax) and **Logic** (enemies, triggers) sub-scenes, so art and design work don't conflict.
- `TileMapLayer` terrain instead of individual bodies.
- Transitions between rooms through doors and screen edges.
