# Map

A world map that fills in as the player explores. The world is a grid of map cells; every room covers a rectangle of them, and each cell shows up on the map the first time the player stands in it. Secrets keep what they hide off the map until they are found, and the player can place marks of their own. It opens from the pause menu or straight from the `map` button (M / Back).

## How it works

### Cells

- One map cell is half a screen of world space: `WorldMap.cell_size`, 320×180 px. A room covers `ceil(bounds.size / cell_size)` cells, so a 1280×360 room is 4×2 cells and a 960×480 room is 3×3.
- Each room says where it sits on the map with `Room.map_cell`: the cell of its top left corner. Rooms joined by an exit should touch on the map, with the exits on the shared edge. Two rooms on the same cells draw over each other; `WorldMap` warns about this in the output when it sees it.
- Each room also has a `map_zone` name. The map shows it for the cell under the cursor and picks the cell colour from it (`MapView.ZONE_COLORS`).

### Scanning rooms

Only one room is loaded at a time, so the map can't read every room up front. Instead, `World._load_room()` calls `WorldMap.enter_room(room)`, which scans the room into a `MapRoom` (`levels/map/map_room.gd`):

1. The cell rectangle from `map_cell` and `bounds`.
2. **Doors.** Every `RoomExit` within 24 px (`MapRoom.EDGE_MARGIN`) of a `bounds` edge is a door on that side of its cell: the wall gets a gap there. Floor holes and ceiling openings count too.
3. **Marks.** A `RoomExit` inside the room (a pressed door) becomes a door mark. Rest points, skill shrines, cleanse points, paid upgrade shrines, flask healers and shop stands become marks on their cell. A cell holds each kind of mark once. Chests, levers and other pickups get no mark: the player marks what they want to remember (see [Player marks](#player-marks)).
4. **Secrets.** Anything behind a secret that hasn't been found is left out (see [Secrets](#secrets)).

The scan reads the room after its saved state is restored, so broken walls are already broken. It replaces what the save had for that room. A secret can be found while the player is in the room, so `WorldMap.refresh()` scans the current room again: before the room unloads, when the map page opens and when the game saves.

### Secrets

A secret is a `Breakable` with a `map_hides` area (px, from the breakable's origin), such as the [secret wall](/systems/traversal#secret-walls). Until it breaks, the scan leaves out everything in that area (`MapSecrets`, `levels/map/map_secrets.gd`):

- **Cells** whose middle is in the area are `hidden`. They aren't drawn, even when revealed, and the cells next to them get a wall on that side, so a hidden part of a room looks like solid rock.
- **Exits** in the area make no door gap and no door mark. A passage to a hidden room shows as a closed wall.
- **Marks** in the area aren't added.

When the secret breaks, the next scan has all of it: the hidden cells show once the player walks into them, and the door gap opens. The map never gives away a secret before it is found, and shows it like any other place after. Rooms the player has never entered are unknown to the map, which is fine: it only draws revealed cells.

### Revealing

`WorldMap` checks the player's cell every `reveal_interval` (0.2 s) while the game runs, and once on every room load. The cell is the player's position in the room, divided by the cell size and kept inside the room's rectangle, so standing on the edge of a room never reveals a cell of the next one. Revealed cells are a set of map coordinates, shared by every room.

### Completion

The map page shows how much of the world is explored, for example `Caves   55% explored`. `WorldMap.completion()` is the revealed cells divided by every cell of every room in the game, rounded down, so it reads 100 % only when every cell is revealed. Cells behind secrets count too, and a cell shared by two rooms counts once. The value is also written to the save as `explored`, for the [slot list](/systems/save-system#save-slots); it is never read back in game.

Only one room is loaded at a time, so the total comes from a **map catalog**: `levels/map/map_catalog.tres`, a `MapCatalog` (`levels/map/map_catalog.gd`) that holds every room scene path and its rectangle of map cells. It is generated, never edited by hand:

```sh
pnpm map:catalog          # rebuild it after adding, moving or resizing a room
```

`tools/build_map_catalog.gd` reads each `.tscn` in `levels/rooms/` as text. A scene whose root node uses `levels/room.gd` is a room, and its `bounds` and `map_cell` give its rectangle (the same `MapCatalog.rect_for()` that `MapRoom.scan()` uses). Reading text instead of loading the scenes keeps it fast and free of autoloads.

Two checks keep the catalog current:

- The lefthook `pre-commit` hook runs `tools/map_catalog.sh --check` when a room scene or the catalog is staged, and fails the commit if the catalog is out of date.
- `WorldMap.enter_room()` warns in the output when the loaded room is missing from the catalog or its rectangle differs.

### Drawing

`MapScreen` (`ui/menus/map/map_screen.gd`) is a page of the pause menu: the zone name with the explored percentage, a `MapView`, a legend of the map's own marks in two rows, and a line of controls that changes while a mark is being placed. `MapView` draws, for each revealed cell:

- The fill: the zone colour, or a bright colour for the player's cell.
- A wall on every side that isn't shared with another cell of the same room, with the middle third left open for a door (`MapCellPainter`). Cells of one room join with no line between them, so a room reads as one shape. A side next to an unrevealed cell of the same room has no wall: there is more to find there.
- Marks: small squares for rest points (orange), skill shrines (cyan), shops (gold), cleanse points (pale blue), paid upgrade shrines and flask healers (purple), inner doors (brown) and death marks still waiting to be recovered (red, from `DeathPenalty.get_shown_marks()`).
- The player's own marks as 5×5 pixel icons on a dark backing (`MapMarkPainter`).
- The player as a blinking dot at their exact spot, and a cursor in the middle of the view.

In travel mode, opened by kneeling at a rest point, the cursor hops between rest points instead of panning, and attack travels. See [Travel](/systems/travel).

Move (stick, D-pad, WASD or arrows) pans the view; it stops at the edge of the revealed cells. Jump switches between the two zoom levels (`MapView.ZOOMS`). Attack places or removes a mark (below). Back closes the page; `map` closes it too when it was opened with `map`.

### Player marks

The player can mark any cell they have been to, to remember a chest they couldn't open, a wall to try, a strong enemy or a place to come back to. `PlayerMarks` (`levels/map/player_marks.gd`) holds them, one per cell, and `WorldMap` owns and saves them.

There are 7 kinds (`PlayerMarks.Kind`): **chest**, **question**, **enemy**, **person** and blue, green and red **pins**.

- **Placing:** move the cursor onto a cell and press attack. A row of the 7 kinds opens at the bottom of the view (`MapMarkPicker`), with the name of the chosen one above it. Left and right choose, attack (or accept) places it, back cancels. Panning stops while the row is open.
- **Where:** `WorldMap.can_place_mark()`: a revealed cell the map shows, with none of the map's own marks (rest point, shrine, shop, cleanse point, upgrade shrine, door) and no player mark yet. On any other cell attack does nothing.
- **Removing:** attack on a cell with a player mark removes it. To change a mark, remove it and place another.

Player marks are saved with the map, so they last until the save is deleted.

### Saving

`WorldMap` is a global save system (`save_id` `world_map`). It saves every scanned room (with its hidden cells), the revealed cells and the player's marks. Like everything else, it reaches the disk when the game saves: at rest points and on death.

## Files

| File | Role |
|---|---|
| `levels/map/world_map.gd` | `WorldMap`: scans rooms (again on `refresh()`), reveals the player's cell, saves the map. A child of `World` |
| `levels/map/map_catalog.gd` | `MapCatalog`: every room's cells, for the completion percentage; `rect_for()` |
| `levels/map/map_catalog.tres` | The generated catalog, set on `WorldMap.catalog` in `world.tscn` |
| `tools/build_map_catalog.gd` | Builds the catalog from the room scenes, or checks it with `--check` |
| `tools/map_catalog.sh` | Runs the builder with Godot (`$GODOT`, the macOS app, or `godot` on `PATH`) |
| `levels/map/map_room.gd` | `MapRoom`: one room's cells, hidden cells, doors and marks; scan from a `Room`, save data |
| `levels/map/map_secrets.gd` | `MapSecrets`: a room's secrets while scanning; says what they still hide |
| `levels/map/player_marks.gd` | `PlayerMarks`: the marks the player placed, one per cell, save data |
| `ui/menus/map/map_screen.gd` | `MapScreen`: the pause menu's map page with zone name, explored percentage and legend |
| `ui/menus/map/map_view.gd` | `MapView`: draws the map, pans and zooms; hands control to `MapTravel` in travel mode |
| `ui/menus/map/map_travel.gd` | `MapTravel`: travel mode, see [Travel](/systems/travel) |
| `ui/menus/map/map_cell_painter.gd` | `MapCellPainter`: one cell's fill, walls and door gaps, and the map's mark squares |
| `ui/menus/map/map_mark_painter.gd` | `MapMarkPainter`: the 5×5 icon of each player mark kind |
| `ui/menus/map/map_mark_picker.gd` | `MapMarkPicker`: the row of mark kinds shown while placing one |

## Tuning

| Value | Where | Default | Effect |
|---|---|---|---|
| `map_cell` | `Room` | `Vector2i(0, 0)` | Map cell of the room's top left corner |
| `map_zone` | `Room` | `"Steppe"` | Zone name on the map; picks the cell colour |
| `cell_size` | `WorldMap` | `Vector2i(320, 180)` | World size of one map cell (px) |
| `reveal_interval` | `WorldMap` | `0.2` | Seconds between checks of the player's cell |
| `pan_speed` | `MapView` | `6.0` | Panning speed, in cells per second |
| `ZOOMS` | `MapView` | `32×18`, `16×9` | Size of one cell on screen per zoom level (px) |
| `ZONE_COLORS` | `MapView` | Steppe, Caves, Works | Fill colour per zone name |
| `EDGE_MARGIN` | `MapRoom` | `24` | How close to a room edge (px) an exit must be to count as a door in the wall |
| `map_hides` | `Breakable` | empty | Area (px) a secret keeps off the map until it breaks. Vault's alcove wall: `(0, -64, 136, 64)` |

### Test rooms on the map

| Room | `map_cell` | Cells | Zone |
|---|---|---|---|
| `test_house` | (-2, 0) | 2×2 | Steppe |
| `test_room` | (0, 0) | 4×2 | Steppe |
| `test_cave` | (4, 0) | 3×2 | Caves |
| `test_shaft` | (4, 2) | 3×3 | Caves |
| `test_works` | (7, 0) | 4×4 | Works |
| `test_vault` | (11, 0) | 3×4 | Vault |
| `test_hideout` | (14, 0) | 2×2 | Vault |

The hideout is behind the vault's secret wall: the vault's east door gap stays closed on the map until the wall is broken.

## Extending

- **A new room:** put the scene in `levels/rooms/`, set `map_cell` so it touches the rooms its exits lead to, and `map_zone`, then run `pnpm map:catalog`. A room scene must set `bounds` and `map_cell` in its own `.tscn` or rely on the `Room` defaults; the builder copies those defaults, so change both together.
- **A new zone:** give rooms the new `map_zone` name and add a colour for it to `MapView.ZONE_COLORS`.
- **A new mark:** add it to the end of `MapRoom.Mark` (saves store marks as numbers), detect it in `MapRoom.scan()`, and give it a colour in `MapView.MARK_COLORS` and a legend entry in one of the `MapScreen.LEGEND` rows.
- **A new player mark kind:** add it to the end of `PlayerMarks.Kind` with a name in `PlayerMarks.NAMES`, and an icon and colour in `MapMarkPainter.ICONS` and `COLORS`.
- **A secret on the map:** give any `Breakable` a `map_hides` area over what it hides: the passage behind it, the exit to a hidden room, or whole cells (their middles must be inside).

## Known limitations

- Completion counts map cells only, not items, upgrades or secrets found.
- The catalog builder only finds rooms directly in `levels/rooms/` whose root uses `room.gd` itself, not a script extending it. Its cell size is a copy of `WorldMap.cell_size`.
- No items that reveal a whole zone yet. Travel works only from a rest point, not from the pause menu's map.
- Player marks can't be placed on a cell with one of the map's own marks, and there is one per cell.
- Cells, walls and marks are flat colours drawn in code, not art.
- Rooms are rectangles on the map. An L-shaped room shows as its bounding rectangle.
