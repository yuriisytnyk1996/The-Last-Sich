# Rooms

A room is one playable area of the world. `levels/room.gd` (`Room`) provides the shared logic. `levels/test_room.tscn` is the current test level and the main scene.

## What a room does

1. Places the player at `SpawnPoint` when the room loads.
2. Limits the player's camera to `bounds`, so nothing outside the room is ever shown.
3. Kills the player (or an enemy) instantly when they enter `KillZone` (a bottomless pit), whatever health is left, with `Health.kill()`. The player goes through the normal death: the **Dead** state, the HUD bar empties, and after `death_delay` the Dead state emits `Events.player_died`. Invincibility doesn't protect against pits.
4. Respawns the player at `SpawnPoint` when `Events.player_died` fires. `Player.respawn()` restores full health.
5. At the same moment, calls `reset()` on every node in the `enemies` group: each enemy returns to its spawn point with full health, including dead ones. See [Enemies](/systems/enemies#respawning).

## Required nodes

| Node | Type | Purpose |
|---|---|---|
| `SpawnPoint` | `Marker2D` | Where the player appears and respawns |
| `KillZone` | `Area2D` (layer `hazards`, mask `player` and `enemies`) | Bottomless pit: kills the player or an enemy on contact, ignoring health |
| `Player` | Instance of `player.tscn` | The player |

## Settings

| Value | Default | Effect |
|---|---|---|
| `bounds` | `Rect2i(0, 0, 1280, 360)` | Playable area and camera limits (px) |

## Terrain

Solid ground is painted on a `TileMapLayer` named `Terrain`, using the shared tileset `levels/terrain/terrain.tres`. The tileset's physics layer puts every tile on the `world` physics layer, so the player, enemies and their ledge probes collide with it like any other body.

| Tile | Atlas coords | Collision |
|---|---|---|
| Solid block | `(0, 0)` | Full 16×16 square |
| One-way plank | `(1, 0)` | Top 4 px only, one-way: you can jump up through it and land on top |

The tiles are 16×16 px. The texture `levels/terrain/terrain_tiles.png` is a placeholder: flat colours with a light top edge.

### Platform heights

The player's full jump reaches 52 px (`jump_height`). Keep every climb at **2 tiles (32 px)** or less. Climbs of 3 tiles (48 px) are technically in reach but need a near-perfect full jump, so don't use them on the main path. A running jump carries about 70 px across at the same height, so keep gaps at 4 tiles (64 px) or less.

A ledge needs at least 3 tiles (48 px) of clear space below it before the player (30 px tall) can walk under it. A one-tile ledge with less room below acts as a wall, so build it as a block down to the ground instead.

## Test room layout

The test room is 1280×360 (two screens wide, 80×22 tiles). It contains:

- Ground on both sides of a pit, with a kill zone in the pit
- Walls at both edges
- A low step (2 tiles high) on the left, then a mid ledge 2 tiles above it
- A one-way bridge (lighter colour) over the pit, level with the mid ledge
- A step block on the right side with a high ledge 2 tiles above it
- Spikes (red) on the right ground, under `Hazards`: a continuous `Hitbox` on the `hazards` layer that deals 1 damage. See [Combat](/systems/combat#hazards)
- Two raiders under `Enemies`: `RaiderGround` patrols the right ground between the step and the right wall, `RaiderLedge` patrols the high ledge and shows ledge turning. See [Enemies](/systems/enemies)

## Making a new room

1. Create a new scene with a `Node2D` root and attach `levels/room.gd`.
2. Add `SpawnPoint`, `KillZone` and an instance of `player.tscn`. Put enemy instances under an `Enemies` node.
3. Add a `TileMapLayer` named `Terrain`, set its tileset to `levels/terrain/terrain.tres` and paint the ground. Follow the [platform heights](#platform-heights) rules.
4. Set `bounds` to the room's size.

## Planned

- Split rooms into **Layout** (collision), **Deco** (art and parallax) and **Logic** (enemies, triggers) sub-scenes, so art and design work don't conflict.
- Real tile art with terrain autotiling (corners and edges picked automatically).
- Transitions between rooms through doors and screen edges.
