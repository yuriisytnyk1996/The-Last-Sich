# Rooms

A room is one playable area of the world. `levels/room.gd` (`Room`) provides the shared logic. The rooms themselves live in `levels/rooms/`. The world scene, `levels/world.tscn` (`World`), owns the player and the HUD and swaps rooms when the player walks through an exit.

## How it works

1. `World` loads `start_room` into its `RoomHolder` and calls `Room.enter(player, exit_name)`. The room sets the camera limits to its `bounds` and returns where the player should stand: the `Landing` of the named exit, or `SpawnPoint` when the name is empty (the start of the game).
2. A room kills the player (or an enemy) instantly when they enter `KillZone` (a bottomless pit), whatever health is left, with `Health.kill()`. The player goes through the normal death: the **Dead** state (the body stops where it is, below the screen, so the camera stays put), the HUD bar empties, and after `death_delay` the Dead state emits `Events.player_died`. Invincibility doesn't protect against pits.
3. When `Events.player_died` fires and no [rest point](/systems/rest-points) has been used, `World` calls `Room.respawn_player()`, which respawns the player where they entered the room: the landing they arrived at, or `SpawnPoint` at the start of the game or when the exit they came through has `respawn_here` off. `Player.respawn()` restores full health.
4. At the same moment, the room calls `reset()` on every node in the `enemies` group: each enemy returns to its spawn point with full health, including dead ones. `World` also forgets every killed enemy, so the enemies of other rooms are back too. See [Enemies](/systems/enemies#respawning).

## Room transitions

A `RoomExit` (`levels/objects/room_exit.gd`) is an `InteractionArea` (see [Interaction areas](#interaction-areas)) that only detects the `player` layer. Its node name is its id. It points at another room (`target_room`) and at the exit there to arrive through (`target_exit`). Two linked exits point at each other by name. There are two kinds:

- **Edge exits** (`press_interact` off): a gap in the wall at the edge of the room. Touching it is enough.
- **Vertical exits** (`press_interact` off): a hole in the floor or an opening in the ceiling. See [Vertical exits](#vertical-exits).
- **Doors** (`press_interact` on): an instance of `levels/objects/door.tscn`, standing on the ground. The player stands in front of it and presses interact. See [Doors](#doors).

1. The player touches an edge exit, or presses interact in front of a door. It emits `Events.room_change_requested(target_room, target_exit)`.
2. `World` pauses the game and `ScreenFade` (`ui/screen_fade.gd`) fades to black. Nothing can hit the player while the screen is dark.
3. `World` frees the old room, loads the new one and calls `Room.enter()`, which calls `RoomExit.receive()` on the target exit: the player is placed at its `Landing` marker and turned to `arrival_facing` (unless it is `Keep`). The camera snaps there without smoothing.
4. `Events.player_arrived` is sent (a running Wagon Fort circle moves to the player), the game unpauses and the screen fades back in. Further requests are ignored until the fade finishes.

The player is never recreated, so health, velocity and the current state carry over: walking into an exit, you walk out of the other one. Rooms are loaded when needed and freed when left. Coming back, enemies you killed there stay dead until you rest or die, and the ones left alive start fresh. See [Enemies](/systems/enemies#respawning).

Keep each edge exit's `Landing` outside its own exit area, or the player would bounce straight back. A good spot is 40 px inside the room, standing on the ground.

### Vertical exits

A vertical exit is an ordinary `RoomExit` laid flat: a 64×8 area just below the bottom edge of a hole (y = room height + 4), or just above an opening in the ceiling (y = -4). Two linked exits sit at the same x in both rooms so the drop feels continuous.

- **Falling down.** The player falls into the hole and arrives at the `Landing` of the ceiling exit in the room below, 44 px under the top edge so the whole body is below the area. Velocity carries over, so they keep falling.
- **Jumping up.** The player jumps into the ceiling opening and arrives at the `Landing` of the floor exit in the room above, just above its area (12 px). That landing is inside the hole, so the floor exit has `arrival_rise` set: a player who arrives moving up is launched to rise that many pixels (64 in the test cave), enough to clear the floor and steer onto the ground beside the hole. They arrive in the **Fall** state, so releasing jump doesn't cut the launch short.

Neither landing is safe ground, so both exits have `respawn_here` off: dying after arriving through them respawns the player at the room's `SpawnPoint`.

To make jumping up possible, put something to jump from within reach under the ceiling opening. In the test shaft that's a stack of one-way planks right below it.

### Ladders

A `Ladder` (`levels/objects/ladder.gd`) is a `Node2D` with a placeholder drawing (`@tool`, so it shows in the editor). Its origin is the **top centre** and it reaches `height` px down. It has no collision: the player finds ladders by position through the `ladders` group. See [Climbing ladders](/systems/player#climbing-ladders) for the controls.

- Make it 16 px wide on the tile grid: put its x on the middle of a tile column (`16 × column + 8`).
- Put a **one-way plank** tile at the top, level with the ladder's top, so the player can stand on it, walk across, and climb down with down. The player climbs up through it and ends standing on it.
- Let the bottom reach the floor, or hang it in the air: running off the bottom lets go.

**Ladders between rooms.** A ladder can go down through a hole in the floor into the room below. Add a 16×8 `RoomExit` under the hole (like a [vertical exit](#vertical-exits)) and make the ladder reach past it, and in the room below an exit above the ceiling opening with a ladder starting above the room's top edge (y = -16) so the landing is on it. Both landings must be on the ladders (12 px above the floor exit, 44 px below the ceiling exit) and both exits have `respawn_here` off. The player keeps climbing through the transition.

### Doors

`levels/objects/door.tscn` is a `RoomExit` with `press_interact` on, a 24×44 placeholder door, a 20×40 area and a `Prompt` arrow above it. Its origin is the bottom centre: place it on the ground. The `Landing` sits on the origin, inside the area. That's safe for doors: entering needs a fresh press of interact, so holding it while you arrive doesn't send you back. Set `arrival_facing` so the player arrives facing into the room.

The player can use a door only from **Idle** or **Run**, on the ground (`Player.can_interact()`). Interact while jumping, dashing, attacking or staggered does nothing.

## Interaction areas

`InteractionArea` (`components/interaction/interaction_area.gd`) is the base for anything the player sets off: room exits, doors and [rest points](/systems/rest-points). It's an `Area2D` on no layer that masks `player`.

| `press_interact` | Sets off when |
|---|---|
| Off | The player touches the area |
| On | The player is inside and `can_interact()` returns true (interact just pressed, on the ground, in Idle or Run) |

While the player is inside an interact area, its `Prompt` child (any `CanvasItem`, optional) is shown. Subclasses override `_activate(player)`. The area doesn't import `Player`: it calls `can_interact()` on whatever body enters, so other bodies are ignored.

**Blocking.** Every interaction area joins the `interaction_areas` group. Another area on the same spot can call `block()` on it to go first, and `unblock()` when it's done; blocks from several areas add up. While blocked, an area hides its prompt and ignores interact. The press that unblocks it never sets it off in the same physics frame, so one press does one thing. `get_bounds()` gives an area's rectangle in global coordinates for overlap checks. [Death marks](/systems/death-penalty#recovering) use this to go before doors and rest points.

## Files

| File | Role |
|---|---|
| `levels/world.tscn`, `levels/world.gd` | Gameplay scene, started from the [main menu](/systems/menus). Owns the player, HUD, debug labels, screen fade and pause menu. Loads rooms, runs transitions, handles death (rest point or room respawn) |
| `levels/room.gd` | Base room: camera bounds, pits, respawn point, enemy reset, `get_enemies()`. Finds its nodes inside the `Layout` and `Logic` parts |
| `levels/killed_enemies.gd` | `KilledEnemies`: keeps killed enemies dead across room changes until the player rests or dies |
| `levels/objects/room_exit.gd` | Edge exit or door to another room |
| `levels/objects/ladder.gd` | Climbable ladder, found by position |
| `levels/objects/door.tscn` | Door: a `RoomExit` entered by pressing interact |
| `components/interaction/interaction_area.gd` | Touch or interact area, base of `RoomExit` |
| `ui/screen_fade.gd` | Black overlay that fades out and in, runs while paused and during hit-stop |
| `levels/rooms/<name>.tscn` | A room: the `Room` root and its three parts |
| `levels/rooms/<name>/deco.tscn`, `layout.tscn`, `logic.tscn` | The parts of that room |

## Room structure

Each room is split into three sub-scenes, so an artist and a level designer can work on the same room at once without touching the same file. The room scene itself only holds the `Room` script, its `bounds` and the three instances:

```
levels/rooms/test_room.tscn   TestRoom (Room)
├── Deco     levels/rooms/test_room/deco.tscn     art, drawn first
├── Layout   levels/rooms/test_room/layout.tscn   what the player collides with
└── Logic    levels/rooms/test_room/logic.tscn    what happens in the room
```

| Part | Holds | Rule |
|---|---|---|
| **Deco** | Background, and later tile art, props, parallax and lighting | Never collides and has no scripts that change gameplay. Safe to change without retesting the level |
| **Layout** | `Terrain`, `Ladder` nodes, `Hazards` (spikes, traps), `Zones`, `Platforms` and `KillZone` | Everything that decides where the player can stand, climb or die. Follow the [platform heights](#platform-heights) |
| **Logic** | `SpawnPoint`, `Exits`, `Enemies`, rest points, training dummies, later triggers and pickups | Things that act, react or are saved. Node paths in here are saved, so renaming one loses its saved state |

The parts are drawn in that order: Deco behind, then Layout, then Logic. Art that must go in front of the player (foreground pillars, grass) stays in Deco with a higher `z_index`. All three share the room's coordinates: their roots sit at (0, 0), so a position means the same thing in every part.

`Room` finds its nodes by path: `Logic/SpawnPoint`, `Layout/KillZone` and `Logic/Exits`. Save keys are paths inside the room too, such as `Logic/RestPoint`.

**Editing a room.** Open the part you want to change (`layout.tscn` to paint ground) rather than the room scene. To see the other parts while editing, open the room scene, where all three show together. Changes made there to an instanced part's children stay in the room scene as overrides, so make them in the part's own file instead.

### Room nodes

| Node | Part | Type | Required | Purpose |
|---|---|---|---|---|
| `Background` | Deco | `ColorRect` | No | Placeholder backdrop the size of `bounds` |
| `Terrain` | Layout | `TileMapLayer` | Yes | Ground and walls, see [Terrain](#terrain) |
| `Ladder` nodes | Layout | `Ladder` | No | Ladders |
| `Hazards` | Layout | `Node2D` holding `Spikes`, hazard `Hitbox`es, timed traps and turrets | No | Hazards, see [Environment](/systems/environment) |
| `Zones` | Layout | `Node2D` holding wind, mud and poison zones | No | Areas that change the player, see [Environment](/systems/environment#zones) |
| `Platforms` | Layout | `Node2D` holding moving platforms, elevators and their call levers | No | See [Environment](/systems/environment) |
| `KillZone` | Layout | `Area2D` (layer `hazards`, mask `player` and `enemies`) | No | Bottomless pit: kills the player or an enemy on contact, ignoring health |
| `SpawnPoint` | Logic | `Marker2D` | Yes | Where the player starts when the room is the start room |
| `Exits` | Logic | `Node2D` holding `RoomExit` areas and door instances | No | Ways to other rooms. Each exit has a `Shape` and a `Landing` marker |
| `Enemies` | Logic | `Node2D` holding enemy instances | No | Enemies of the room |
| `Breakables` | Logic | `Node2D` holding crates and cracked walls | No | Props broken by attacks; saved when they stay broken. See [Environment](/systems/environment#breakables) |

Rooms don't contain the player, the HUD or the debug labels: those live in `World`.

## Tuning

| Value | Where | Default | Effect |
|---|---|---|---|
| `bounds` | `Room` | `Rect2i(0, 0, 1280, 360)` | Playable area and camera limits (px) |
| `map_cell` | `Room` | `Vector2i(0, 0)` | Where the room sits on the [world map](/systems/map), in map cells |
| `map_zone` | `Room` | `"Steppe"` | Zone name on the map |
| `music` | `Room` | none | Music while here; empty keeps what is playing. See [Audio](/systems/audio#music) |
| `start_room` | `World` | `res://levels/rooms/test_room.tscn` | The room the game starts in |
| `target_room` | `RoomExit` | empty | Room to load (an exit with no target does nothing) |
| `target_exit` | `RoomExit` | empty | Name of the exit in `target_room` to arrive through |
| `arrival_facing` | `RoomExit` | `Keep` | Which way the player faces after arriving through this exit: `Keep`, `Left` or `Right` |
| `height` | `Ladder` | `64.0` | Length of the ladder down from its top (px) |
| `arrival_rise` | `RoomExit` | `0.0` | Height (px) a player arriving while moving up is launched to. For floor holes the player comes up through. 0 keeps their speed |
| `respawn_here` | `RoomExit` | `true` | Off when the landing isn't safe ground: a death in the room then respawns at `SpawnPoint` |
| `press_interact` | `InteractionArea` | `false` | Needs interact pressed inside the area instead of a touch. On in `door.tscn` |
| `duration` | `ScreenFade` | `0.15` | Seconds for one fade, out or in, unless the caller asks for its own time (a [cutscene](/systems/cutscenes)) |

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
- A [rest point](/systems/rest-points) at the far left (x 48), next to the spawn point
- A door (`HouseDoor`) near the start, leading to the test house
- The elder (x 496), between the hare foot and the barracks door: rewards for the captives, the Sich letters and the Otaman, see [test content](/systems/story#test-content)
- A second door (`BarracksDoor`) on the ground just left of the pit, leading to the test barracks
- A low step (2 tiles high) on the left, then a mid ledge 2 tiles above it. The owl feather and a tier relic lie on top of the step
- A one-way bridge (lighter colour) over the pit, level with the mid ledge
- A step block on the right side with a high ledge 2 tiles above it
- Spikes (red, 40 px wide) on the right ground, under `Hazards`: instant death when stepped in, easy to jump over. See [Combat](/systems/combat#spikes)
- Two raiders under `Enemies`: `RaiderGround` patrols the right ground between the step and the right wall, `RaiderLedge` patrols the high ledge and shows ledge turning. See [Enemies](/systems/enemies)
- A musketeer under `Enemies` on the raised block right of the pit (x 832 to 960), shooting down at the floor and across the pit

## Test cave layout

`levels/rooms/test_cave.tscn` is 960×360 and sits east of the test room. It has a ceiling, a `West` exit back to the test room in the gap at the bottom of the left wall, a step, a ledge, a one-way plank above the ledge and one raider. The old kobzar (x 220), right of the rest point, and his chest (x 252) that appears once his quest is done; a captive cage (x 420). See [test content](/systems/story#test-content). A 4-tile hole in the floor right of the plank (x 704 to 768) is the `Down` exit to the test shaft. Further right, a ladder goes down through a one-tile hole covered by a plank (x 848 to 864), through the `LadderDown` exit into the shaft. It has no pits, so no `KillZone`. An `East` exit in the gap at the bottom of the right wall leads to the test works, see [Environment](/systems/environment#test-works-layout).

## Test shaft layout

`levels/rooms/test_shaft.tscn` is 960×480 and sits under the test cave. Its `Up` exit is an opening in the ceiling at the same x as the cave's hole. Under it is a stack of one-way planks 2 tiles apart: falling in, you land on the top one; drop through them (down + jump) to reach the floor, and jump up through them to climb back. From the top plank, a jump reaches the opening and takes you back to the cave. A ladder (`LadderUp`) runs the full height of the shaft, from the floor up through a one-tile opening in the ceiling into the cave. One raider patrols the floor. In the open left half, three vanishing [crumbling platforms](/systems/environment#crumbling-platforms) climb from the floor like stairs (x 600, 536, 472; they come back after 3 s), and from the top one a collapsing bridge of six segments runs west at y 312 (x 248 to 424) and stays down until the room loads again. Against the left wall a [timed platform sequence](/systems/environment#timed-platform-sequences) of six steps zigzags up from the floor (x 96 and 160, y 392 to 192) to a one-way ledge at y 160 (x 16 to 64) with a crate worth 30.

## Test house layout

`levels/rooms/test_house.tscn` is a closed 640×360 room behind the test room's door. It has a `Door` back to the test room, a [rest point](/systems/rest-points) in the middle and a one-way plank 2 tiles above the floor. A `West` opening in its left wall leads to the [test crypt](/systems/environment#test-crypt-layout).

## Test barracks layout

`levels/rooms/test_barracks.tscn` is a closed 1280×360 room behind the test room's `BarracksDoor`, for testing the newer enemies. It sits above the test room on the map (`map_cell` (0, -2)). From left to right:

- The `Door` back to the test room, at the spawn point.
- A low wall (2 tiles), then the **shieldbearer**'s stretch: it patrols between this wall and the next, so there is room to jump over it.
- A second low wall, the boar's crash wall and the player's cover: standing behind it blocks the boar's sight, so it can't charge.
- The **boar**'s run: long flat ground, so a charge from the right reaches the wall.
- A third low wall, then the **crow**'s area: a one-way plank 2 tiles up, and a solid shelf 4 tiles up near the right wall to hide under from the crow.
- The `KurganDoor` (x 1176), leading to the [test kurgan](#test-kurgan-layout), and the `ArenaDoor` against the right wall, leading to the test arena.
- A Sich letter (x 236) past the first low wall and a captive cage (x 680) on the boar's run, see [test content](/systems/story#test-content).

## Test arena layout

`levels/rooms/test_arena.tscn` is a closed 960×360 room behind the barracks' `ArenaDoor`, for testing bosses. It sits above the barracks on the map (`map_cell` (0, -4), zone "Arena"). From left to right:

- The `Door` back to the barracks, at the spawn point, and a rest point.
- The arena gate (open until the fight starts), under a solid wall up to the ceiling so the gate is the only way in.
- The arena floor with the `BossArena` trigger over all of it, two one-way planks 3 tiles up, and the **Otaman** near the right wall.
- The boss intro cutscene (`Intro`) beside the arena, with its `BossView` marker over the Otaman.

See [Bosses](/systems/bosses).

## Test kurgan layout

`levels/rooms/test_kurgan.tscn` is a closed 1920×360 dusk room behind the barracks' `KurganDoor`, for testing [cutscenes](/systems/cutscenes). It sits east of the barracks on the map (`map_cell` (4, -2), zone "Kurgan"). From left to right:

- The `Door` back to the barracks, at the spawn point, and a rest point.
- The graves: crosses in the backdrop and two one-way planks, and the Grave keeper (`KeeperRoad`, x 760).
- The `Ambush` trigger (x 1160), then the palisade: a solid wall up to the ceiling with a gate (x 1312) as the only way through.
- Two raiders between the palisade and the mound.
- The burial mound: three one-tile steps up to the stone idol (x 1760), whose interact area starts the `Vigil`. After the vigil the keeper stands at its foot (`KeeperMound`, x 1568).
- The three cutscenes and their `CutsceneMarks` in `Logic`.

See [Enemies](/systems/enemies).

## Making a new room

1. Make a folder `levels/rooms/<name>/` with three scenes, each with a `Node2D` root at (0, 0): `deco.tscn` (root `Deco`), `layout.tscn` (root `Layout`) and `logic.tscn` (root `Logic`). Duplicating another room's folder is quickest.
2. Create `levels/rooms/<name>.tscn` with a `Node2D` root, attach `levels/room.gd` and set `bounds` to the room's size. Instance the three parts as children, named `Deco`, `Layout` and `Logic`, in that order.
3. In `layout.tscn`, add a `Terrain` tile layer (tileset `levels/terrain/terrain.tres`) and paint the ground. Follow the [platform heights](#platform-heights) rules. Add a `KillZone` if the room has pits.
4. In `logic.tscn`, add a `SpawnPoint` marker and put enemy instances under an `Enemies` node.
5. For each way out, leave a gap in the wall (4 tiles high is enough), and add a `RoomExit` under `Exits` in `logic.tscn`: an `Area2D` with `collision_layer` 0, `collision_mask` `player`, `monitorable` off, a `Shape` covering the gap at the room edge and a `Landing` marker inside the room. Set `target_room` and `target_exit`, and make the exit in the other room point back.
6. Keep the floor at the same height on both sides of a linked pair, so walking through feels continuous.
7. For a hole down to another room, leave a gap in the floor and add a 64×8 `RoomExit` just below it, with its `Landing` 12 px above the area. In the room below, add the matching exit just above an opening in the ceiling with its `Landing` 44 px below. Set `respawn_here` off on both, and `arrival_rise` on the floor exit if players can jump up into it. See [Vertical exits](#vertical-exits).
8. For a ladder, add a `Ladder` node in `layout.tscn` with a plank tile at its top. See [Ladders](#ladders).
9. For a door, instance `levels/objects/door.tscn` under `Exits`, on the ground, and set `target_room`, `target_exit` and `arrival_facing`.
10. Place the room on the [world map](/systems/map): set `map_cell` so it touches the rooms its exits lead to, and `map_zone`.

## Planned

- Real tile art with terrain autotiling (corners and edges picked automatically).
- Locked doors that need a key item (after the save system and inventory).
- Loading rooms in the background, so big rooms don't hitch.
