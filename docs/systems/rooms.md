# Rooms

A room is one playable area of the world. `levels/room.gd` (`Room`) provides the shared logic. The rooms themselves live in `levels/rooms/`. The main scene, `levels/world.tscn` (`World`), owns the player and the HUD and swaps rooms when the player walks through an exit.

## How it works

1. `World` loads `start_room` into its `RoomHolder` and calls `Room.enter(player, exit_name)`. The room sets the camera limits to its `bounds` and returns where the player should stand: the `Landing` of the named exit, or `SpawnPoint` when the name is empty (the start of the game).
2. A room kills the player (or an enemy) instantly when they enter `KillZone` (a bottomless pit), whatever health is left, with `Health.kill()`. The player goes through the normal death: the **Dead** state, the HUD bar empties, and after `death_delay` the Dead state emits `Events.player_died`. Invincibility doesn't protect against pits.
3. When `Events.player_died` fires, the room respawns the player where they entered it (the landing they arrived at, or `SpawnPoint`). `Player.respawn()` restores full health.
4. At the same moment, it calls `reset()` on every node in the `enemies` group: each enemy returns to its spawn point with full health, including dead ones. See [Enemies](/systems/enemies#respawning).

## Room transitions

A `RoomExit` (`levels/objects/room_exit.gd`) is an `InteractionArea` (see [Interaction areas](#interaction-areas)) that only detects the `player` layer. Its node name is its id. It points at another room (`target_room`) and at the exit there to arrive through (`target_exit`). Two linked exits point at each other by name. There are two kinds:

- **Edge exits** (`press_up` off): a gap in the wall at the edge of the room. Touching it is enough.
- **Doors** (`press_up` on): an instance of `levels/objects/door.tscn`, standing on the ground. The player stands in front of it and presses up. See [Doors](#doors).

1. The player touches an edge exit, or presses up in front of a door. It emits `Events.room_change_requested(target_room, target_exit)`.
2. `World` pauses the game and `ScreenFade` (`ui/screen_fade.gd`) fades to black. Nothing can hit the player while the screen is dark.
3. `World` frees the old room, loads the new one and calls `Room.enter()`, which calls `RoomExit.receive()` on the target exit: the player is placed at its `Landing` marker and turned to `arrival_facing` (unless it is `Keep`). The camera snaps there without smoothing.
4. The game unpauses and the screen fades back in. Further requests are ignored until the fade finishes.

The player is never recreated, so health, velocity and the current state carry over: walking into an exit, you walk out of the other one. Rooms are loaded when needed and freed when left, so enemies in a room you come back to start fresh.

Keep each edge exit's `Landing` outside its own exit area, or the player would bounce straight back. A good spot is 40 px inside the room, standing on the ground.

### Doors

`levels/objects/door.tscn` is a `RoomExit` with `press_up` on, a 24×44 placeholder door, a 20×40 area and a `Prompt` arrow above it. Its origin is the bottom centre: place it on the ground. The `Landing` sits on the origin, inside the area. That's safe for doors: entering needs a fresh press of up, so holding up while you arrive doesn't send you back. Set `arrival_facing` so the player arrives facing into the room.

The player can use a door only from **Idle** or **Run**, on the ground (`Player.can_interact()`). Up while jumping, dashing, attacking or staggered does nothing.

## Interaction areas

`InteractionArea` (`components/interaction/interaction_area.gd`) is the base for anything the player sets off: room exits, doors and (later) rest points. It's an `Area2D` on no layer that masks `player`.

| `press_up` | Sets off when |
|---|---|
| Off | The player touches the area |
| On | The player is inside and `can_interact()` returns true (up just pressed, on the ground, in Idle or Run) |

While the player is inside a press-up area, its `Prompt` child (any `CanvasItem`, optional) is shown. Subclasses override `_activate(player)`. The area doesn't import `Player`: it calls `can_interact()` on whatever body enters, so other bodies are ignored.

## Files

| File | Role |
|---|---|
| `levels/world.tscn`, `levels/world.gd` | Main scene. Owns the player, HUD, debug labels and screen fade. Loads rooms and runs transitions |
| `levels/room.gd` | Base room: camera bounds, pits, respawn point, enemy reset |
| `levels/objects/room_exit.gd` | Edge exit or door to another room |
| `levels/objects/door.tscn` | Door: a `RoomExit` entered by pressing up |
| `components/interaction/interaction_area.gd` | Touch or press-up area, base of `RoomExit` |
| `ui/screen_fade.gd` | Black overlay that fades out and in, runs while paused and during hit-stop |
| `levels/rooms/*.tscn` | The rooms |

## Room nodes

| Node | Type | Required | Purpose |
|---|---|---|---|
| `SpawnPoint` | `Marker2D` | Yes | Where the player starts when the room is the start room |
| `Terrain` | `TileMapLayer` | Yes | Ground and walls, see [Terrain](#terrain) |
| `Exits` | `Node2D` holding `RoomExit` areas and door instances | No | Ways to other rooms. Each exit has a `Shape` and a `Landing` marker |
| `KillZone` | `Area2D` (layer `hazards`, mask `player` and `enemies`) | No | Bottomless pit: kills the player or an enemy on contact, ignoring health |
| `Enemies` | `Node2D` holding enemy instances | No | Enemies of the room |

Rooms don't contain the player, the HUD or the debug labels: those live in `World`.

## Tuning

| Value | Where | Default | Effect |
|---|---|---|---|
| `bounds` | `Room` | `Rect2i(0, 0, 1280, 360)` | Playable area and camera limits (px) |
| `start_room` | `World` | `res://levels/rooms/test_room.tscn` | The room the game starts in |
| `target_room` | `RoomExit` | empty | Room to load (an exit with no target does nothing) |
| `target_exit` | `RoomExit` | empty | Name of the exit in `target_room` to arrive through |
| `arrival_facing` | `RoomExit` | `Keep` | Which way the player faces after arriving through this exit: `Keep`, `Left` or `Right` |
| `press_up` | `InteractionArea` | `false` | Needs up pressed inside the area instead of a touch. On in `door.tscn` |
| `duration` | `ScreenFade` | `0.15` | Seconds for one fade, out or in |

## Terrain

Solid ground is painted on a `TileMapLayer` named `Terrain`, using the shared tileset `levels/terrain/terrain.tres`. The tileset has two physics layers: solid tiles are on the `world` physics layer and one-way planks on the `platforms` layer. The player, enemies and their floor probes mask both, so they collide with the tiles like any other body. Keeping planks on their own layer is what lets the player [drop through them](/systems/player#dropping-through-platforms).

| Tile | Atlas coords | Collision |
|---|---|---|
| Solid block | `(0, 0)` | Full 16×16 square |
| One-way plank | `(1, 0)` | `platforms` layer, top 4 px only, one-way: you can jump up through it, land on top, and drop through with down + jump |

The tiles are 16×16 px. The texture `levels/terrain/terrain_tiles.png` is a placeholder: flat colours with a light top edge.

### Platform heights

The player's full jump reaches 52 px (`jump_height`). Keep every climb at **2 tiles (32 px)** or less. Climbs of 3 tiles (48 px) are technically in reach but need a near-perfect full jump, so don't use them on the main path. A running jump carries about 70 px across at the same height, so keep gaps at 4 tiles (64 px) or less.

A ledge needs at least 3 tiles (48 px) of clear space below it before the player (30 px tall) can walk under it. A one-tile ledge with less room below acts as a wall, so build it as a block down to the ground instead.

## Test room layout

The test room is 1280×360 (two screens wide, 80×22 tiles). It contains:

- Ground on both sides of a pit, with a kill zone in the pit
- Walls at both edges, with a gap at the bottom of the right wall: the `East` exit leads to the test cave
- A door (`HouseDoor`) near the start, leading to the test house
- A low step (2 tiles high) on the left, then a mid ledge 2 tiles above it
- A one-way bridge (lighter colour) over the pit, level with the mid ledge
- A step block on the right side with a high ledge 2 tiles above it
- Spikes (red) on the right ground, under `Hazards`: a continuous `Hitbox` on the `hazards` layer that deals 1 damage. See [Combat](/systems/combat#hazards)
- Two raiders under `Enemies`: `RaiderGround` patrols the right ground between the step and the right wall, `RaiderLedge` patrols the high ledge and shows ledge turning. See [Enemies](/systems/enemies)

## Test cave layout

`levels/rooms/test_cave.tscn` is 960×360 and sits east of the test room. It has a ceiling, a `West` exit back to the test room in the gap at the bottom of the left wall, a step, a ledge, a one-way plank above the ledge and one raider. It has no pits, so no `KillZone`.

## Test house layout

`levels/rooms/test_house.tscn` is a closed 640×360 room behind the test room's door. It has a `Door` back to the test room and a one-way plank 2 tiles above the floor.

## Making a new room

1. Create a new scene in `levels/rooms/` with a `Node2D` root and attach `levels/room.gd`. Set `bounds` to the room's size.
2. Add a `SpawnPoint` marker, a `Terrain` tile layer (tileset `levels/terrain/terrain.tres`) and paint the ground. Follow the [platform heights](#platform-heights) rules.
3. Put enemy instances under an `Enemies` node. Add a `KillZone` if the room has pits.
4. For each way out, leave a gap in the wall (4 tiles high is enough), and add a `RoomExit` under `Exits`: an `Area2D` with `collision_layer` 0, `collision_mask` `player`, `monitorable` off, a `Shape` covering the gap at the room edge and a `Landing` marker inside the room. Set `target_room` and `target_exit`, and make the exit in the other room point back.
5. Keep the floor at the same height on both sides of a linked pair, so walking through feels continuous.
6. For a door, instance `levels/objects/door.tscn` under `Exits`, on the ground, and set `target_room`, `target_exit` and `arrival_facing`.

## Planned

- Split rooms into **Layout** (collision), **Deco** (art and parallax) and **Logic** (enemies, triggers) sub-scenes, so art and design work don't conflict.
- Real tile art with terrain autotiling (corners and edges picked automatically).
- Vertical exits (falling into the room below, jumping up into the room above).
- Locked doors that need a key item (after the save system and inventory).
- Loading rooms in the background, so big rooms don't hitch.
