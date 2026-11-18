# Death penalty

Every death leaves a **death mark** where the player last stood safely. Each mark weakens the player (less max spirit, slower spirit and currency gain) until they walk back and recover it. Pits and spikes are deaths like any other.

The penalty gives death a lasting cost and a reason to return to where it happened, while never taking away upgrades, and staying recoverable.

## How it works

### Safe ground

`PlayerSafeGround` (`actors/player/abilities/safe_ground.gd`) remembers the last spot that is safe to come back to. Every physics frame it counts the player's position as safe when all of these hold:

- the player is in **Idle** or **Run** and on the floor,
- there is ground under both sides, `edge_margin` px left and right of the feet (one ray each), and that ground will still be there later (see below),
- no hazard (spikes, pits: the `hazards` physics layer) within `hazard_margin` px sideways,
- the player is at least `bounds_margin` px from the room's left and right edges.

Ground that comes and goes never counts, or a mark could hang over a pit once it's gone. Each ray checks the body it hits:

- bodies in the `no_safe_ground` group (`PlayerSafeGround.NO_SAFE_GROUP`) never count. Crumbling, timed and reveal platforms join it in `_ready()`; moving platforms and elevators join it unless their `safe_ground` is on,
- a body with an `is_moving()` method doesn't count while it returns true, so a moving platform or elevator with `safe_ground` on only counts while it waits at an end.

It stores the room's scene path with the spot. `World` calls `enter_room()` on every room load. The old spot stays until the player stands somewhere safe in the new room, so dying right after a room change leaves the mark in the previous room. With no safe spot yet (just loaded), the current room's respawn position is used. The spot isn't saved.

### Leaving a mark

On `Events.player_died`, `World` calls `DeathPenalty.drop(room)` (`levels/death_penalty.gd`) before respawning the player:

1. With `max_marks` marks already out, no new mark is added.
2. Otherwise a mark is added at the safe spot. If an unlinked mark in the same room is within `link_distance`, the new one **links** to it: it gets no marker of its own, and recovering the older mark recovers both (`DeathMarkList`, `levels/death_mark_list.gd`). Dying over and over at one hard spot doesn't pile up markers.
3. The penalty is applied for the new count.
4. The player respawns, the room's markers are placed, and the game **saves**, so quitting can't undo the death.

### The penalty

Three tables on `DeathPenalty`, indexed by the number of marks, set the player's factors:

| Marks | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| `spirit_max_factor` (max spirit) | 1.0 | 0.9 | 0.8 | 0.7 | 0.6 | 0.5 |
| `spirit_gain_factor` (spirit per hit) | 1.0 | 0.85 | 0.7 | 0.55 | 0.4 | 0.25 |
| `currency_gain_factor` (currency per kill) | 1.0 | 0.9 | 0.8 | 0.7 | 0.6 | 0.5 |

They go to `PlayerSpirit.max_factor`, `PlayerSpirit.gain_factor` and `PlayerWallet.gain_factor`. Past the end of a table its last value is used. Health and healing flasks are never touched.

The HUD shows the penalty in two places: the [spirit bar](/systems/hud#spirit-bar-and-death-marks) draws the locked part of spirit at its right end, and one pip per mark sits next to it (`Events.death_marks_changed`).

### Recovering

`DeathPenalty.place_in(room)` runs on every room load and spawns a `DeathMark` (`levels/objects/death_mark.tscn`) for each unlinked mark in that room. A death mark is an `InteractionArea` with `press_interact`: standing at it shows the prompt, pressing **interact** recovers it.

A mark always goes first. When it spawns, it blocks every press-interact area whose shape overlaps its own (a door, a rest point; see [Interaction areas](/systems/rooms#interaction-areas)): their prompts hide and interact does nothing there. When the mark leaves the tree (recovered, cleared, or its room unloaded) it unblocks them. So with a mark on a door, the first press takes the mark and the next press opens the door. Touch areas (edge exits, floor holes) are never blocked; safe ground keeps marks away from them anyway.

Recovering a mark:

1. The mark and every mark linked to it are removed, and the factors go back up.
2. The player heals `recover_heal` × max health (rounded, at least 1) and gains `recover_spirit` × max spirit (using the new, higher maximum).

### Paid cleanse

A **cleanse point** (`CleansePoint`, `levels/objects/cleanse_point.tscn`) clears every mark at once for currency, so the player doesn't have to walk back to each one. It is a press-interact `InteractionArea`:

1. Pressing interact pauses the game and opens a `PausingMenu` with a `CleanseScreen` (`ui/menus/shop/cleanse_screen.gd`), the same way a [shop stand](/systems/shops) opens its buy page.
2. The screen shows the number of marks, the price (`price_per_mark` × marks) and the player's currency. **Leave** is focused first. **Cleanse** is disabled and reads "Not enough currency" when the wallet holds less than the price. With no marks it only says so and offers Leave.
3. **Cleanse** calls `PlayerWallet.spend()`, then `DeathPenalty.clear()`: every mark and marker is removed and the factors go back to full. Unlike recovering a mark by hand, there is **no heal or spirit bonus**.

The point finds the penalty through the `death_penalty` group (`DeathPenalty.GROUP`), since the penalty lives in the `World`, not the room. It can be used any number of times and saves nothing of its own: the cleared marks and the spent currency reach the disk with the next save (rest or death), like a shop purchase. The [map](/systems/map) marks it with a pale blue square.

The test house has one, between the rest point and the skill shrine.

### Saving

`DeathPenalty` is a global save system (`death_penalty`, see [Save system](/systems/save-system)):

```json
"death_penalty": {
  "marks": [
    { "id": 1, "room": "res://levels/rooms/test_room.tscn", "x": 240, "y": 320, "linked": [2], "is_linked": false },
    { "id": 2, "room": "res://levels/rooms/test_room.tscn", "x": 270, "y": 320, "linked": [], "is_linked": true }
  ],
  "next_id": 3
}
```

## Files

| File | Role |
|---|---|
| `levels/death_penalty.gd` | `DeathPenalty`: leaves marks, applies the penalty, places and recovers markers, saved |
| `levels/death_mark_list.gd` | `DeathMarkList`: the marks, linking, recovery, save data |
| `levels/objects/death_mark.gd` | `DeathMark`: interact-to-recover area |
| `levels/objects/death_mark.tscn` | Death mark scene (placeholder post) |
| `levels/objects/cleanse_point.gd` / `.tscn` | `CleansePoint`: pay to clear every mark |
| `ui/menus/shop/cleanse_screen.gd` | `CleanseScreen`: marks, price, currency, cleanse or leave |
| `actors/player/abilities/safe_ground.gd` | `PlayerSafeGround`: remembers the last safe spot and its room |
| `levels/objects/spikes.gd` | Instant-death spikes, see [Combat](/systems/combat#spikes) |
| `ui/hud/death_mark_counter.gd` | HUD pips |
| `levels/world.gd` | Calls `drop()` on death, `place_in()` on room load, saves after the respawn |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `DeathPenalty.max_marks` | 5 | Most marks out at once |
| `DeathPenalty.link_distance` | 64 | A new mark this close to an older one in the same room links to it (px) |
| `DeathPenalty.spirit_max_factor` | see table | Max spirit per number of marks |
| `DeathPenalty.spirit_gain_factor` | see table | Spirit gain per number of marks |
| `DeathPenalty.currency_gain_factor` | see table | Currency gain per number of marks |
| `DeathPenalty.recover_heal` | 0.33 | Part of max health healed on recovery |
| `DeathPenalty.recover_spirit` | 0.5 | Part of max spirit given on recovery |
| `CleansePoint.price_per_mark` | 150 | Currency per mark cleared at a cleanse point |
| `PlayerSafeGround.edge_margin` | 12 | Ground must be under each side this far from the feet (px) |
| `PlayerSafeGround.probe_depth` | 4 | How far below the feet the ground may be (px) |
| `PlayerSafeGround.hazard_margin` | 24 | No hazard within this distance sideways (px) |
| `PlayerSafeGround.bounds_margin` | 24 | Distance kept from the room's left and right edges (px) |

## Extending

- **A new cleanse point:** place `cleanse_point.tscn` in a room's Logic scene. Set `price_per_mark` for one that is cheaper or dearer than usual.
- **Rooms without marks or with a fixed mark spot** (boss arenas, where walking back means refighting): add a room setting and have `drop()` read it.
- **An item that prevents marks:** a flag on `DeathPenalty` that makes `drop()` return early.
- **Ground that must never count:** add the body to `PlayerSafeGround.NO_SAFE_GROUP` in its `_ready()`. For ground that is only unsafe at times, give it an `is_moving()` method.

## Known limitations

- Placeholder look for the marks, no sound or effect on recovery.
- No map marker showing where the marks are.
- The factor tables and the cleanse price are a first guess and need playtesting.
- A cleanse point is a grey basin with a pale strip of water, with no sound or effect.
