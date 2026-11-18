# Travel

Travel takes the player from one rest point to any other they have found, so a long walk back through cleared rooms is one choice on the map. It is earned: the player needs the **Chumak's whip** keepsake, and they can only travel while kneeling at a rest point.

## How it works

### Kneeling

1. The player rests at a [rest point](/systems/rest-points) as usual: health, flasks, enemies and the save are handled first.
2. If they have the `rest_travel` unlock (`PlayerUnlocks.REST_TRAVEL`), the rest point then puts the player in the **Kneel** state (`actors/player/states/kneel.gd`). The player stops, can't be hit (the hurtbox is off, so there is no invincibility blink) and goes down on one knee (placeholder: the visual squashes toward the feet to `kneel_height`). The game keeps running for `kneel_time`, so the HUD shows health (and flasks, spirit) refilling before anything pauses. Then Kneel sends `Events.travel_offered`. The Chumak's whip grants this unlock while carried (an `UnlockEffect` with an `OWNED` trigger, see [Traversal](/systems/traversal#unlocks)).
3. `World` opens the pause menu on a `KneelScreen` (`ui/menus/rest/kneel_screen.gd`): a small panel at the bottom of the screen such as "M: travel    Escape: rise". It names the real keys: the bound `map` key and Escape on keyboard, or the bound `map` button and B on a gamepad (`BindingButton.key_name()` / `button_name()`). It shows gamepad names when a gamepad is connected and switches to whichever device was used last. The game is paused, but the screen has no tint (`MenuScreen.backdrop` off), so the player stays in view.
4. **Back** or **interact** closes the menu: the player takes `rise_time` to get up, then plays on. **Map** (M / Back) opens the travel map on top of the prompt.

Without the unlock, resting works exactly as before and no prompt shows.

### The travel map

The travel map is the [map](/systems/map) page in travel mode (`MapScreen.new(map, true)`). It looks the same, with the title **Travel**, but the cursor works differently. `MapView` hands control to a `MapTravel` (`ui/menus/map/map_travel.gd`):

- **Targets:** every revealed map cell with a rest point mark. A rest point only has to have been seen, not used.
- **Start:** the cursor starts on the middle of the player's own cell, the rest point they kneel at.
- **Moving:** there is no free panning. A push of move (past the `dead_zone`) looks for a target in that direction. It checks cones around the pushed direction, narrowest first (`cones`: 30°, 40°, 60° either side). The nearest target in the first cone with one wins. Pushing where there is nothing does nothing.
- **Gliding:** the view glides to the chosen cell at `speed` screen px/s, easing in and out (quad). Meanwhile the cursor, a small square, swells to twice its size and shrinks back. New pushes are ignored until the glide ends. Holding a direction hops from rest point to rest point.
- **Travel possible:** when the cursor rests on a target that isn't the player's own cell. The cursor is bright, and the hint reads "Attack: travel". Elsewhere the cursor is dim and the hint leaves travel out.
- **Zoom and marks are off** in travel mode. Jump doesn't zoom and attack doesn't place marks. The zone name, the legend, the map's marks, the player's marks and the death marks still show.
- **Back** closes the whole menu, not just the map: the player rises. `map` closes it too.

### Arriving

1. Attack on a target sends `Events.travel_requested(room_path, cell)`. `room_path` is the room that owns the cell on the map.
2. `World` closes the menu, waits one frame (the menu unpauses the tree one frame after it closes), then runs its usual fade transition.
3. While the screen is black, `World` loads the room. It finds the `RestPoint` whose position falls in the chosen map cell (`World._rest_point_at()`) and respawns the player on it.
4. It sends `Events.rested` for that rest point, so travelling there makes it the respawn point: it lights, the killed-enemy list clears and the game saves. Health and flasks aren't refilled; the player just rested.
5. If the room no longer has a rest point in that cell (the room changed since the map saw it), the player arrives at the room's spawn point instead, with a warning in the output.

## Files

| File | Role |
|---|---|
| `levels/objects/rest_point.gd` | Sends `Events.travel_offered` after a rest when travel is unlocked |
| `actors/player/states/kneel.gd` | Kneel state: holds the player still with the hurtbox off, opens the prompt after `kneel_time`, rises after it closes |
| `ui/menus/rest/kneel_screen.gd` | `KneelScreen`: the kneel prompt. Map opens the travel map, back or interact rises |
| `ui/menus/map/map_travel.gd` | `MapTravel`: targets, cone search, glide, cursor pulse, whether travel is possible |
| `ui/menus/map/map_view.gd` | Hands move input and cursor drawing to `MapTravel` in travel mode; sends `travel_chosen` |
| `ui/menus/map/map_screen.gd` | Travel title and hints; turns `travel_chosen` into `Events.travel_requested`; back closes the menu |
| `ui/menus/pause/pause_menu.gd` | `open_kneel()` |
| `levels/world.gd` | Opens the prompt, runs the travel transition, places the player and sets the respawn point |
| `actors/player/abilities/unlocks.gd` | `PlayerUnlocks.REST_TRAVEL` |
| `actors/player/items/keepsakes/chumak_whip.tres` | The keepsake that grants travel |
| `autoload/events.gd` | `travel_offered`, `travel_requested(room_path, cell)` |

## Tuning

`MapTravel` is made in code, so these are its defaults:

| Value | Default | Effect |
|---|---|---|
| `cones` | `[30, 40, 60]` | Half-angles (degrees) searched in turn around the pushed direction |
| `dead_zone` | `0.2` | Stick push (0 to 1) needed to move |
| `speed` | `400` | Glide speed of the view (screen px/s) |
| `cursor_size` | `8` | Side of the cursor square (px) at rest. It doubles mid-glide |

The Kneel state (on the player's `StateMachine/Kneel` node) has its own values:

| Value | Default | Effect |
|---|---|---|
| `kneel_time` | 0.8 | Seconds to go down on one knee, with the game running; the prompt opens when it ends |
| `rise_time` | 0.3 | Seconds to get up after the prompt closes |
| `kneel_height` | 0.65 | Height of the player's visual while kneeling, as a fraction of standing height |

The Chumak's whip costs 600 at the test house [shop](/systems/shops).

## Extending

- **A new rest point to travel to:** place `levels/objects/rest_point.tscn` in a room. Any rest point the map has seen is a target. The test house and the test cave each have one.
- **Two rest points in one map cell:** only one can be told apart, since travel picks by cell. Keep rest points in separate cells.
- **A way back without the map:** the [Duma of the Road Home](/systems/dumas#dumas) takes the player to the last rest point used, from anywhere.
- **Another source of travel:** grant `PlayerUnlocks.REST_TRAVEL` from any item through an `UnlockEffect`. A later progression system can grant it instead.

## Known limitations

- The kneel is a placeholder squash of the visual, not an animation. No sounds for the prompt, the glide or a push with no target.
- Travel opens on every rest once unlocked. A rest point has no "first lit" state of its own.
- The cursor is a plain square drawn in code.
