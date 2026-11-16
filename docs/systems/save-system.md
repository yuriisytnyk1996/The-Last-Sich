# Save system

Saves the game to disk so closing it doesn't lose progress. Today it keeps the last [rest point](/systems/rest-points) used. It is built so that any room object (an opened door, a picked-up item, a one-off enemy) and any global system (inventory, upgrades) can add its own state without the save system knowing about it.

## How it works

All saved state lives in one **snapshot** dictionary in the `SaveManager` autoload (`autoload/save_manager.gd`):

```json
{
  "version": 2,
  "global": {
    "world": { "rest_room": "res://levels/rooms/test_house.tscn", "rest_path": "Logic/RestPoint" }
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

- **Global systems** live for the whole run. They call `SaveManager.register(self)` and have a `save_id`, which is their key under `global`. They're dropped automatically when they leave the tree. `World` saves the last rest point, `PlayerWallet` the player's currency, `PlayerSkills` the learned skills and the tier (see [Skills](/systems/skills)), `PlayerInventory` the owned and worn items (see [Inventory](/systems/inventory)), `DeathPenalty` the death marks (see [Death penalty](/systems/death-penalty)) and `WorldMap` the rooms seen and the revealed map cells (see [Map](/systems/map)).
- **Room objects** are any nodes in the `persistent` group inside a room. Their key is their node path inside the room, under that room's scene path in `rooms`.

The flow:

1. **Start.** `World._ready()` registers itself and calls `SaveManager.load_game()`. If a save exists, each registered system gets its data back, and `World` loads the rest point's room and places the player on it. With no save (or a rest point room that no longer exists), the game starts in `start_room` as before.
2. **Room unloads.** Before `World` frees a room, `SaveManager.store_room(room)` writes every persistent node's data into the snapshot. This is in memory only.
3. **Room loads.** Right after the room is added to the tree (so `_ready()` has run) and before the player enters, `SaveManager.restore_room(room)` hands each persistent node its stored data.
4. **Rest.** On `Events.rested`, `World` remembers the rest point and calls `SaveManager.save_game(room)`. That stores the current room, collects every global system's data and writes the snapshot to disk.
5. **Death.** After the player respawns, `World` saves the same way, so a death mark can't be undone by quitting.

Rooms you visited since the last rest are in the snapshot, so they are written too when you rest. Dying doesn't roll the snapshot back: what you changed in a room stays changed.

### Writing to disk

`SaveFile` (`components/save/save_file.gd`) handles the file. It is plain, readable JSON in `user://save_<slot>.json`.

- **Safe writes.** It writes to `save_<slot>.json.tmp` first, then renames that over the slot. A crash mid-write leaves the old save intact.
- **Backup.** Every successful load copies the slot to `save_<slot>.json.bak`. If the slot can't be read, the backup is loaded and copied back over it.
- **Version.** The snapshot has a `version`. A save with a different version is ignored, and the game starts fresh. Bump `FORMAT_VERSION` when the layout changes in a way old saves can't follow (and add a migration then, if saves are worth keeping).

`SaveManager` refuses to start a save while another one is running, and logs an error.

### Debug

In debug builds, **F8** deletes the save and restarts the game from `start_room`.

## Files

| File | Role |
|---|---|
| `autoload/save_manager.gd` | `SaveManager`: snapshot, registry of global systems, room store/restore, load/save/delete, F8 debug key |
| `components/save/save_file.gd` | `SaveFile`: JSON slot file with safe writes and a backup |
| `levels/world.gd` | Global system `world`: saves the last rest point, loads the save on start, saves on rest, stores and restores rooms |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `SaveManager.slot` | `0` | Which slot is read and written. Set it before `World` starts (a slot menu, later). |
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

- One slot, no slot selection. That comes with the main menu.
- Only resting and dying save. Quitting between them loses what you did since, including currency earned.
- The player's health isn't saved: loading puts you on a rest point, which heals you to full anyway.
- No play time or other slot details for a load screen yet.
- No migration between format versions: a version bump throws old saves away.
