# Save system

Saves the game to disk so closing it doesn't lose progress, in one of three save slots picked on the main menu. Today it keeps the last [rest point](/systems/rest-points) used. It is built so that any room object (an opened door, a picked-up item, a one-off enemy) and any global system (inventory, upgrades) can add its own state without the save system knowing about it.

## How it works

All saved state lives in one **snapshot** dictionary in the `SaveManager` autoload (`autoload/save_manager.gd`):

```json
{
  "version": 2,
  "global": {
    "world": { "rest_room": "res://levels/rooms/test_house.tscn", "rest_path": "Logic/RestPoint", "zone": "Steppe" },
    "play_clock": { "seconds": 3725.0 }
  },
  "rooms": {
    "res://levels/rooms/test_house.tscn": { "SomeDoor": { "opened": true } }
  }
}
```

There are two kinds of participants. Both implement the same two methods:

```gdscript
func get_save_data() -> Dictionary
func apply_save_data(data: Dictionary) -> void
```

- **Global systems** live for the whole run. They call `SaveManager.register(self)` and have a `save_id`, which is their key under `global`. They're dropped automatically when they leave the tree. `World` saves the last rest point and the zone of the room it saved in, `PlayClock` the time played, `PlayerWallet` the player's currency, `PlayerSkills` the learned skills and the tier (see [Skills](/systems/skills)), `PlayerInventory` the owned and worn items (see [Inventory](/systems/inventory)), `DeathPenalty` the death marks (see [Death penalty](/systems/death-penalty)) and `WorldMap` the rooms seen and the revealed map cells (see [Map](/systems/map)).
- **Room objects** are any nodes in the `persistent` group inside a room. Their key is their node path inside the room, under that room's scene path in `rooms`.

The flow:

1. **Start.** The main menu sets `SaveManager.slot` (see [Save slots](#save-slots)). `World._ready()` registers itself and calls `SaveManager.load_game()`. If a save exists, each registered system gets its data back, and `World` loads the rest point's room and places the player on it. With no save (or a rest point room that no longer exists), the game starts in `start_room` and saves at once, so the slot shows as taken.
2. **Room unloads.** Before `World` frees a room, `SaveManager.store_room(room)` writes every persistent node's data into the snapshot. This is in memory only.
3. **Room loads.** Right after the room is added to the tree (so `_ready()` has run) and before the player enters, `SaveManager.restore_room(room)` hands each persistent node its stored data.
4. **Rest.** On `Events.rested`, `World` remembers the rest point and calls `SaveManager.save_game(room)`. That stores the current room, collects every global system's data and writes the snapshot to disk.
5. **Death.** After the player respawns, `World` saves the same way, so a death mark can't be undone by quitting.

Rooms you visited since the last rest are in the snapshot, so they are written too when you rest. Dying doesn't roll the snapshot back: what you changed in a room stays changed.

### Save slots

There are `SaveManager.SLOT_COUNT` (3) slots, `save_0.json` to `save_2.json`, shown to the player as 1 to 3. The main menu picks one before the world starts:

- **Continue** on the title screen loads the slot written most recently (`SaveManager.latest_slot()`, by file time). It is hidden when no slot is taken or that slot can't be loaded.
- **Play** opens the slot list (`SlotsScreen`). Each row shows the slot number, the zone, the play time, how much of the map is explored and the currency, or **Empty**. An empty slot starts a new game in it right away. A taken slot opens its page (`SlotScreen`): **Continue** and **Delete**, which asks first.
- A slot with another format version shows as **Old save**, one that can't be read (nor its backup) as **Damaged save**. Neither loads; their page offers **New game here** (asked first) and **Delete**.

The rows come from `SlotSummary.read(slot)`, which reads the file with `SaveFile.peek()`: no backup copy is made just for showing the list. The summary takes its values from the global systems' own data (`world.zone`, `play_clock.seconds`, `wallet.amount`, and `world_map.explored`, which `WorldMap` writes from `completion()` only for this list), so no system writes a separate summary. Saves made before the zone was kept show **Unknown**.

`PlayClock` (`levels/play_clock.gd`, a node in `world.tscn`) adds up the time played. It stops while the tree is paused, so menus and room transitions don't count.

### Writing to disk

`SaveFile` (`components/save/save_file.gd`) handles the file. It is plain, readable JSON in `user://save_<slot>.json`.

- **Safe writes.** It writes to `save_<slot>.json.tmp` first, then renames that over the slot. A crash mid-write leaves the old save intact.
- **Backup.** Every successful load copies the slot to `save_<slot>.json.bak`. If the slot can't be read, the backup is loaded and copied back over it.
- **Version.** The snapshot has a `version`. A save with a different version is ignored, and the game starts fresh. Bump `FORMAT_VERSION` when the layout changes in a way old saves can't follow (and add a migration then, if saves are worth keeping).

`SaveManager` refuses to start a save while another one is running, and logs an error.

### Debug

In debug builds, **F8** deletes the current slot's save and restarts the game from `start_room`.

## Files

| File | Role |
|---|---|
| `autoload/save_manager.gd` | `SaveManager`: current slot, snapshot, registry of global systems, room store/restore, load/save/delete, latest slot, F8 debug key |
| `components/save/save_file.gd` | `SaveFile`: JSON slot file with safe writes and a backup; `peek()` reads without side effects |
| `components/save/slot_summary.gd` | `SlotSummary`: a slot's state, zone, play time and currency for the slot list |
| `levels/world.gd` | Global system `world`: saves the last rest point and zone, loads the save on start, saves on rest and on a new game, stores and restores rooms |
| `levels/play_clock.gd` | Global system `play_clock`: time played in the slot |
| `ui/menus/main_menu/slots_screen.gd`, `slot_row.gd`, `slot_screen.gd` | Slot list, one slot's row, one slot's page (see [Menus](/systems/menus)) |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `SaveManager.slot` | `0` | Which slot is read and written. The main menu sets it before `World` starts |
| `SaveManager.SLOT_COUNT` | `3` | How many slots the slot list shows |
| `SaveManager.FORMAT_VERSION` | `2` | Saves with another version are ignored. Version 2 came with the [room split](/systems/rooms#room-structure), which changed node paths inside rooms |
| `SaveFile.SLOT_PATH` | `user://save_%d.json` | Where slots are written |

On macOS, `user://` is `~/Library/Application Support/Godot/app_userdata/The Last Sich/`.

## Extending

**A room object that remembers its state**, e.g. a door that stays open:

```gdscript
func _ready() -> void:
	add_to_group(SaveManager.PERSISTENT_GROUP)


func get_save_data() -> Dictionary:
	return {"opened": opened}


func apply_save_data(data: Dictionary) -> void:
	opened = data.get("opened", false)
	_update_visual()
```

Keep the node's name and place in the room stable: its path is its id. Renaming or moving it loses its saved state.

**A global system** (an inventory autoload, for example):

```gdscript
var save_id := &"inventory"


func _ready() -> void:
	SaveManager.register(self)
```

Register before `World` calls `load_game()`. Autoloads are ready before any scene, so registering in their `_ready()` is enough.

Values go through JSON, so keep data to strings, numbers, booleans, arrays and dictionaries. Numbers come back as floats: convert with `int()` where needed. Store a `Vector2` as two numbers.

## Known limitations

- Only resting and dying save. Quitting between them loses what you did since, including currency earned.
- The player's health isn't saved: loading puts you on a rest point, which heals you to full anyway.
- The explored share on a slot row only counts map cells, not items or bosses.
- Slots can't be copied.
- No migration between format versions: a version bump throws old saves away.
