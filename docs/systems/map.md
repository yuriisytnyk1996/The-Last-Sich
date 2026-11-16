# Map

A world map that fills in as the player explores. The world is a grid of map cells; every room covers a rectangle of them, and each cell shows up on the map the first time the player stands in it. It opens from the pause menu or straight from the `map` button (M / Back).

## How it works

### Cells

- One map cell is half a screen of world space: `WorldMap.cell_size`, 320×180 px. A room covers `ceil(bounds.size / cell_size)` cells, so a 1280×360 room is 4×2 cells and a 960×480 room is 3×3.
- Each room says where it sits on the map with `Room.map_cell`: the cell of its top left corner. Rooms joined by an exit should touch on the map, with the exits on the shared edge. Two rooms on the same cells draw over each other; `WorldMap` warns about this in the output when it sees it.
- Each room also has a `map_zone` name. The map shows it for the cell under the cursor and picks the cell colour from it (`MapView.ZONE_COLORS`).

### Scanning rooms

Only one room is loaded at a time, so the map can't read every room up front. Instead, `World._load_room()` calls `WorldMap.enter_room(room)`, which scans the room into a `MapRoom` (`levels/map/map_room.gd`):

1. The cell rectangle from `map_cell` and `bounds`.
2. **Doors.** Every `RoomExit` within 24 px (`MapRoom.EDGE_MARGIN`) of a `bounds` edge is a door on that side of its cell: the wall gets a gap there. Floor holes and ceiling openings count too.
3. **Marks.** A `RoomExit` inside the room (a pressed door) becomes a door mark. Rest points and skill shrines become marks on their cell.

The scan replaces what the save had for that room, so changes to a room show up the next time the player walks in. Rooms the player has never entered are unknown to the map, which is fine: it only draws revealed cells.

### Revealing

`WorldMap` checks the player's cell every `reveal_interval` (0.2 s) while the game runs, and once on every room load. The cell is the player's position in the room, divided by the cell size and kept inside the room's rectangle, so standing on the edge of a room never reveals a cell of the next one. Revealed cells are a set of map coordinates, shared by every room.

### Drawing

`MapScreen` (`ui/menus/map/map_screen.gd`) is a page of the pause menu: the zone name, a `MapView` and a legend. `MapView` draws, for each revealed cell:

- The fill: the zone colour, or a bright colour for the player's cell.
- A wall on every side that isn't shared with another cell of the same room, with the middle third left open for a door (`MapCellPainter`). Cells of one room join with no line between them, so a room reads as one shape. A side next to an unrevealed cell of the same room has no wall: there is more to find there.
- Marks: small squares for rest points (orange), skill shrines (cyan), inner doors (brown) and death marks still waiting to be recovered (red, from `DeathPenalty.get_shown_marks()`).
- The player as a blinking dot at their exact spot, and a cursor in the middle of the view.

Move (stick, D-pad, WASD or arrows) pans the view; it stops at the edge of the revealed cells. Jump switches between the two zoom levels (`MapView.ZOOMS`). Back closes the page; `map` closes it too when it was opened with `map`.

### Saving

`WorldMap` is a global save system (`save_id` `world_map`). It saves every scanned room and the revealed cells. Like everything else, it reaches the disk when the game saves: at rest points and on death.

## Files

| File | Role |
|---|---|
| `levels/map/world_map.gd` | `WorldMap`: scans rooms, reveals the player's cell, saves the map. A child of `World` |
| `levels/map/map_room.gd` | `MapRoom`: one room's cells, doors and marks; scan from a `Room`, save data |
| `ui/menus/map/map_screen.gd` | `MapScreen`: the pause menu's map page with zone name and legend |
| `ui/menus/map/map_view.gd` | `MapView`: draws the map, pans and zooms |
| `ui/menus/map/map_cell_painter.gd` | `MapCellPainter`: one cell's fill, walls and door gaps |

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

### Test rooms on the map

| Room | `map_cell` | Cells | Zone |
|---|---|---|---|
| `test_house` | (-2, 0) | 2×2 | Steppe |
| `test_room` | (0, 0) | 4×2 | Steppe |
| `test_cave` | (4, 0) | 3×2 | Caves |
| `test_shaft` | (4, 2) | 3×3 | Caves |

## Extending

- **A new room:** set `map_cell` so it touches the rooms its exits lead to, and `map_zone`.
- **A new zone:** give rooms the new `map_zone` name and add a colour for it to `MapView.ZONE_COLORS`.
- **A new mark:** add it to `MapRoom.Mark`, detect it in `MapRoom.scan()`, and give it a colour in `MapView.MARK_COLORS` and a legend entry in `MapScreen.LEGEND`.

## Known limitations

- No completion percentage: the map only knows the rooms the player has entered, so it can't count the cells left. That needs a list of every room.
- No marks placed by the player, no fast travel from the map and no items that reveal a whole zone yet.
- Cells, walls and marks are flat colours drawn in code, not art.
- Rooms are rectangles on the map. An L-shaped room shows as its bounding rectangle.
