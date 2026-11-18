# Traversal

Ways through the world and places locked behind something the player finds later: walls marked for climbing with the wall jump, platforms they can only see with the right item, gates opened by a lever on the far side, chests and secret alcoves. Finding an item opens up rooms that were already visited, which is what makes the world worth exploring twice.

## How it works

### Unlocks

`PlayerUnlocks` (`actors/player/abilities/unlocks.gd`, the `Unlocks` node on the player) is the list of traversal abilities the player has. Level objects ask `player.unlocks.has(PlayerUnlocks.REVEAL_PLATFORMS)`.

| Unlock | Given by | Opens |
|---|---|---|
| `reveal_platforms` | Seer's lantern (relic, while worn) | Reveal platforms become solid and visible |
| `rest_travel` | Chumak's whip (keepsake, while carried) | Kneeling at a rest point offers [travel](/systems/travel) to any other found |
| `rest_spirit` | Icon lamp (keepsake, while carried) | Resting fills [spirit](/systems/spirit), and respawning after death starts it full instead of empty |
| `soft_landing` | Owl feather (relic, while worn) | No [hard landing](/systems/player#hard-landing) after long falls |

Unlocks come from items. An `UnlockEffect` (`actors/player/items/effects/unlock_effect.gd`) is an [item effect](/systems/inventory#effects) that grants its unlock when it starts and revokes it when it stops. With an `OWNED` trigger it works while the item is carried; with `EQUIPPED` only while it is worn. One unlock can come from several sources and stays on while any of them holds it.

Traversal tools are **relics**: they work only while worn in one of the 3 relic slots, and the player puts them on and takes them off on the Relics tab of the [inventory page](/systems/inventory#inventory-page). Taking the lantern off hides the platforms again. So finding a tool doesn't switch it on for good: the player chooses which ones to wear.

Unlocks themselves are **not saved**. The inventory is, and loading it starts the item effects again, which grant the unlocks again. So there is one source of truth: the items.

Every change is announced through `Events.player_unlocks_changed`, so room objects react without holding a reference to the player.

### Wall jump

`PlayerWallJump` (`actors/player/abilities/wall_jump.gd`) finds walls to cling to. The **WallCling** and **WallJump** states do the rest. It is a basic move, there from the start: the player drives the blade into the wall and hangs from it. No item or skill is needed.

Not every wall can be climbed. Only walls marked with a `ClimbWall` work, so level design decides where the move is allowed and can't be broken by a wall the designer forgot about.

1. **Grab.** In Jump, Fall or a swing started in the air, `wants_grab()` is true when attack is **held**, down isn't (down + attack is the dive), the player is inside a climb wall, and a solid wall is within `reach` in the direction they **face**. Holding attack is enough: an air swing that reaches the wall with attack still held turns into the grab, and the attack press is used up so it doesn't swing again after the kick. Two rays look for it: one from the middle of the body and one `low_probe_height` above the feet, so a wall beside the legs counts too and a jump from the floor next to a wall catches it at once. It doesn't work for `regrab_delay` after letting go or kicking off. A ledge grab goes first, so falling past a wall top still hangs from the ledge.
2. **Cling.** The player is moved against the wall and faces it. They slide `slide_distance` down over `slide_time`, fast at first, then hold still for as long as they like. The slide stops early where the wall ends, so a grab at the very bottom edge of a wall holds instead of slipping off.
3. **Kick off.** Jump enters **WallJump**: a normal jump with a small `kick_push` away from the wall, turned to face away from it. The input steers it like any jump, so where the player goes is up to the stick: away crosses to the far wall, toward the wall comes straight back to it.
4. **Let go.** Down drops off (Fall). Losing the wall (leaving the climb wall, or a gate under the hands opening) also falls. Landing ends the cling.

A jump pressed just before the grab is kept in the buffer, so it kicks off at once.

Two ways to climb:

- **One wall.** Hold toward the wall and attack, and press jump on each grab. Holding toward the wall turns the player back to face it, and once `regrab_delay` is over they grab it again, still rising: about 40 px higher per jump.
- **A shaft.** Two climb walls facing each other. The kick already faces the player toward the far wall: hold attack and away from the wall, jump, repeat.

`WallJump` extends the Jump state (`PlayerJumpState`) and only overrides `_steer()`, so the jump cut, ladder grab, dive and attacks all work as in a normal jump.

### Climb walls

`ClimbWall` (`levels/objects/traversal/climb_wall.gd`) is an area laid over the wall tiles. The origin is the top left corner and `size` covers the wall; the collision shape reaches `MARGIN` (8 px) further on both sides, into the air the player clings in. It registers itself with `PlayerWallJump` while the player is inside, the same way [zones](/systems/environment#zones) do. It draws placeholder notches down both faces, also in the editor. Put it in the room's `Layout`.

### Reveal platforms

`RevealPlatform` (`levels/objects/traversal/reveal_platform.gd`) is only there for a player who can see it. With the `reveal_platforms` unlock it fades in and turns solid; without it, it is a faint outline (`HIDDEN_ALPHA`) the player falls through. It checks the player on `Events.player_unlocks_changed` and once when the room loads. One-way on the `platforms` layer by default, solid on `world` with `one_way` off. The origin is the top centre, like a [moving platform](/systems/environment#moving-platforms).

### Levers and gates

`Lever` (`levels/objects/mechanisms/lever.gd`) is an [interaction area](/systems/rooms#interaction-areas). Pressing interact flips it and calls a method on every node in `targets`. A lever doesn't know what it drives: anything with that method works. `action` picks the method:

| `action` | Calls | Use |
|---|---|---|
| `TOGGLE` (default) | `toggle()` | Open or close a gate |
| `UNLOCK` | `unlock()` | Free a locked gate without opening it; something else opens it later |

With `one_shot` (the default) it stays pulled and blocks itself, so the prompt is gone for good. With a `key` item set, the lever only moves for a player carrying that item (the key isn't used up). That is how a key-locked door works: a gate driven by a lever with a `key`.

`Gate` (`levels/objects/mechanisms/gate.gd`) blocks the way with a `Body` on the `world` layer. The scene is 32×48, three tiles: enough for the player to walk through, and it leaves as much wall above as possible. `toggle()` or `set_open()` turns its collision off and folds its `Visual` up toward the top over `move_time`, with a small camera shake. `open` sets the state the room starts in. A `locked` gate ignores `toggle()` and `set_open()` until `unlock()` is called, so one lever (in `UNLOCK` mode) can free a gate that another lever operates.

The typical use is a **shortcut**: a gate near the start of an area with its lever on the far side, so the player opens it on the way back and never needs to make the long trip again.

Both are saved. The lever remembers being pulled; the gate remembers being open and locked. Loading a room restores each one directly and never calls `toggle()` again, so a target can't be flipped twice.

### Pressure plates

`PressurePlate` (`levels/objects/mechanisms/pressure_plate.gd`) is a plate on the floor, pressed by any body on the `player` or `enemies` layer standing on it. Pressing calls `set_open(true)` on every node in `targets`. A `Gate` has it, and so can anything else. Its `mode` decides what happens when the plate is left:

| `mode` | Stepping off | Saved |
|---|---|---|
| `HOLD` (default) | Calls `set_open(false)` on the targets after `release_delay`. Stepping back on before then cancels the close | No |
| `LATCH` | Nothing: the plate stays down and the targets stay open | Yes, the plate stays down |

With a `release_delay`, a `HOLD` plate makes a **timed gate**: step on, then run through before it shuts. Several bodies can stand on a plate at once; it rises only when the last one leaves.

A `HOLD` plate owns its targets. When its room loads and nothing is on it, it shuts them at once, after the saved state is restored. Leaving the room while a gate is open can't leave it open for good. Don't drive the same gate with a `HOLD` plate and a lever.

The `Top` child sinks `press_depth` px while the plate is down. Origin is the bottom centre, so place it on the floor.

### Attack switches

`AttackSwitch` (`levels/objects/mechanisms/attack_switch.gd`) is a switch on a post that the player hits instead of pulling. Any hitbox on the `player_attacks` layer flips it: swings, the dive, dumas and the [ranged bolt](/systems/skills), so a switch out of reach (high on a wall, across a gap) is thrown from a distance. Like a lever, it drives every node in `targets` and doesn't know what they are. `action` picks what a hit does:

| `action` | On a hit | Typical use |
|---|---|---|
| `TOGGLE` (default) | `toggle()` | Open or close a gate; every hit flips it back |
| `UNLOCK` | `unlock()` | Free a locked gate that something else opens |
| `TIMED` | `set_open(true)`, then `set_open(false)` after `open_time` | A gate the player has to run through |

With `one_shot` the switch stays on after the first hit and takes no more hits, for shortcuts. A `TIMED` switch ignores hits until it springs back. The head turns and lights up while the switch is on, and every hit flashes it with a small hit-stop and shake.

Its hurtbox has `rewards_attacker` off, so hitting a switch fills no spirit, and a short `invincibility_time` so one swing (or a multi-hit attack) flips it only once.

A `TIMED` switch owns its targets the way a `HOLD` pressure plate does: when its room loads it shuts them at once, so leaving mid-timer can't leave a gate open for good. It isn't saved. The other modes are saved like a lever. Don't drive the same gate with a `TIMED` switch and anything else.

### Chests

`Chest` (`levels/objects/items/chest.gd`) opens once with interact. It gives its `item` through `PlayerInventory.add()` (with the HUD toast) and `currency` straight to the wallet, not scaled by the [death penalty](/systems/death-penalty), since it is a fixed treasure, not a kill reward. Opened chests stay open (saved) and block their own prompt.

### Secret walls

A secret is closed off by a **secret wall** (`levels/objects/breakables/secret_wall.tscn`), a [breakable](/systems/environment#breakables) that looks like the terrain around it. Walking into it does nothing: the player has to suspect it and hit it. It has no crack or other tell.

- Its `Visual/Cover` is drawn like the terrain and above the player (`z_index` 10). It covers the wall and the whole space behind it, so the secret can't be seen from outside. The tiles behind it are open.
- Its `Body` (16×64 at the origin, on the `world` layer) blocks the way in.
- It takes 3 hits, and only from the side the player comes from (`breakable_from`, `LEFT` by default): from inside, the hurtbox is off. Every hit flashes the cover, so a player who tries the right wall gets an answer.
- On the third hit the body opens and the cover fades out over `fade_time` (0.6 s). Hits taken so far and the broken state are saved.
- Its `map_hides` area keeps what it hides off the [map](/systems/map#secrets) until it breaks: cells, door gaps and marks. Then the map shows them like anywhere else. The secret wall's default area is its cover (64×64).

### Saving

Lever, attack switch (except `TIMED`), gate, pressure plate, chest and secret wall join the `persistent` group, so the [save system](/systems/save-system) keeps them per room. Put them in the room's `Logic`, where saved node paths live.

## Test vault layout

`levels/rooms/test_vault.tscn` is a 960×720 room east of the [test works](/systems/environment#test-works-layout), through a new `East` doorway at the bottom of the works' right wall. It walks through the whole loop:

1. **Entrance** (left, ground floor): the doorway from the works.
2. **Shaft** (x 256 to 320): a [rest point](/systems/rest-points) on its floor (x 288), and two climb walls facing each other, entered through a 3-tile gap under the left one. The right wall has the 3-tile gate at its bottom, and its climb wall reaches the floor over the closed gate. Both walls start 48 px above the floor, low enough to catch with a jump from the ground, with the gate closed or open. Wall jump up to the upper floor (y 352), across the shaft or up either wall alone.
3. **Upper floor west**: the **shortcut lever**. It opens the gate at the bottom of the shaft's right wall, so the ground floor connects both halves of the room.
4. **Ground floor east**: a chest with the **seer's lantern**, a relic to wear from the inventory. The player drops down here from the upper floor, or walks through the opened gate.
5. **Gap** (x 560 to 720): two reveal platforms bridge it while the lantern is worn.
6. **Upper floor east**: the secret wall at the end, broken from the west, hides an alcove with a chest worth 300 and a free [health upgrade](/systems/upgrades). The alcove runs through the room's east wall into the **test hideout** (`test_hideout.tscn`, 640×360): a hidden room with a chest worth 250 on a one-way ledge. Its `map_hides` covers the alcove and the `East` exit, so the map shows a closed wall there until the wall breaks.

The hideout also tests [pressure plates](#pressure-plates). On its floor, a `HOLD` plate (x 336, `release_delay` 2 s) opens the timed gate at x 528, and a `LATCH` plate (x 400) opens the gate at x 592 for good. Further west, a gate at x 240 closes the entrance corridor; a one-shot [attack switch](#attack-switches) in front of it (x 192) opens it for good.

The shaft is the only way past the entrance until the gate is open. Without the lantern worn, the gap can't be crossed.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/unlocks.gd` | `PlayerUnlocks`: unlocks held by sources, announced through `Events` |
| `actors/player/items/effects/unlock_effect.gd` | `UnlockEffect`: item effect that grants an unlock |
| `actors/player/items/relics/seer_lantern.tres` | The unlock item that shows reveal platforms |
| `actors/player/abilities/wall_jump.gd` | `PlayerWallJump`: finds climbable walls, wall jump tuning |
| `actors/player/states/wall_cling.gd` | WallCling state: slide, hold, let go |
| `actors/player/states/attacks/player_attack_state.gd` | Air swings turn into a wall grab while attack is held |
| `actors/player/states/wall_jump.gd` | WallJump state: jump with a small push off the wall |
| `actors/player/states/jump.gd` | `PlayerJumpState`: the jump, with the `_steer()` hook |
| `levels/objects/traversal/climb_wall.gd` | `ClimbWall`: marks a wall as climbable |
| `levels/objects/traversal/reveal_platform.gd` | `RevealPlatform`: platform shown by an unlock |
| `levels/objects/breakables/secret_wall.tscn` | Secret wall: a `Breakable` drawn like the terrain, covering the secret behind it |
| `levels/objects/mechanisms/lever.gd`, `.tscn` | `Lever`: toggles its targets |
| `levels/objects/mechanisms/gate.gd`, `.tscn` | `Gate`: blocks the way until opened |
| `levels/objects/mechanisms/attack_switch.gd`, `.tscn` | `AttackSwitch`: drives its targets when hit |
| `levels/objects/mechanisms/pressure_plate.gd`, `.tscn` | `PressurePlate`: opens its targets while pressed or for good |
| `levels/objects/items/chest.gd`, `.tscn` | `Chest`: gives an item and currency once |
| `levels/rooms/test_vault.tscn`, `test_vault/` | Test room with every piece |

## Tuning

| Value | Script | Default | Effect |
|---|---|---|---|
| `reach` | `PlayerWallJump` | 4 | How far in front of the body a wall is grabbed (px) |
| `low_probe_height` | `PlayerWallJump` | 4 | Height of the lower wall probe above the feet (px) |
| `let_go_threshold` | `PlayerWallJump` | 0.5 | Down needed to let go; down this far also stops a grab |
| `slide_distance` | `PlayerWallJump` | 8 | Slide down after grabbing (px) |
| `slide_time` | `PlayerWallJump` | 0.3 | Time of that slide (s) |
| `regrab_delay` | `PlayerWallJump` | 0.2 | No grab after letting go or kicking off (s) |
| `kick_push` | `PlayerWallJump` | 30 | Sideways nudge away from the wall when kicking off (px/s). The rise is a normal jump and the input steers the rest |
| `size` | `ClimbWall` | 32×128 | The wall covered (px) |
| `MARGIN` | `ClimbWall` | 8 | Reach past the wall on each side (px, constant) |
| `size` | `RevealPlatform` | 32×8 | Platform size (px) |
| `one_way` | `RevealPlatform` | true | One-way on `platforms`, or solid on `world` |
| `fade_time` | `RevealPlatform` | 0.4 | Fade in or out (s) |
| `HIDDEN_ALPHA` | `RevealPlatform` | 0.15 | Outline alpha while hidden (constant) |
| `one_shot` | `Lever` | true | Stays pulled after one use |
| `action` | `Lever` | `TOGGLE` | `TOGGLE` calls `toggle()`, `UNLOCK` calls `unlock()` on the targets |
| `key` | `Lever` | none | Item the player must carry to pull it |
| `up_angle` / `pulled_angle` | `Lever` | -0.6 / 0.6 | Handle angle (radians) |
| `open` | `Gate` | false | State when first entered |
| `locked` | `Gate` | false | Ignores `toggle()` and `set_open()` until `unlock()` |
| `move_time` | `Gate` | 0.5 | Time to open or close (s) |
| `move_shake` | `Gate` | 0.2 | Camera trauma when it moves |
| `open_scale` | `Gate` | 0.1 | How much of the gate still shows when open |
| `mode` | `PressurePlate` | `HOLD` | `HOLD` opens the targets while pressed, `LATCH` opens them for good |
| `release_delay` | `PressurePlate` | 0 | `HOLD`: seconds after stepping off before the targets close |
| `press_depth` | `PressurePlate` | 2 | How far the top sinks when pressed (px) |
| `action` | `AttackSwitch` | `TOGGLE` | `TOGGLE`, `UNLOCK` or `TIMED` (see above) |
| `one_shot` | `AttackSwitch` | false | Stays on after the first hit. Test hideout: true |
| `open_time` | `AttackSwitch` | 3 | `TIMED`: seconds the targets stay open |
| `off_angle` / `on_angle` | `AttackSwitch` | 0 / π/4 | Head angle (radians) |
| `off_color` / `on_color` | `AttackSwitch` | grey / gold | Head colour |
| `invincibility_time` | attack switch `Hurtbox` | 0.3 | Time after a hit before another counts (s) |
| `hit_stop` / `shake` | attack switch `HurtFeedback` | 0.04 / 0.1 | Feedback on every hit |
| `currency` | `Chest` | 0 | Currency inside. Secret chest in the vault: 300, in the hideout: 250 |
| `open_angle` | `Chest` | -2.0 | Lid angle when open (radians) |
| `hits` | secret wall | 3 | Hits to break it |
| `breakable_from` | secret wall | `LEFT` | Side the player has to stand on for hits to count |
| `fade_time` | secret wall | 0.6 | Cover fade when it breaks (s) |
| `map_hides` | secret wall | `(0, -64, 64, 64)` | Area kept off the map until it breaks. Vault: `(0, -64, 136, 64)` |

## Extending

- **A new unlock:** add a constant to `PlayerUnlocks` and the name to the `@export_enum` in `UnlockEffect`, give an item an `UnlockEffect` with it, and check `player.unlocks.has()` where it matters. A room object that depends on it listens to `Events.player_unlocks_changed`, like `RevealPlatform`.
- **A key-locked door:** a `Gate` with a `Lever` next to it whose `key` is the key item (a keepsake).
- **A new lever target** (a bridge, a moving platform that starts): give it a `toggle()` method (and `unlock()` if it can be locked) and, if its state should last, join the `persistent` group with `get_save_data()` / `apply_save_data()`.
- **A climbable wall:** draw the wall in the tiles, then lay a `ClimbWall` over it in `Layout` with `size` matching the tiles.
- **A secret:** leave the passage open in the tiles, place `secret_wall.tscn` in `Logic` at the bottom of the way in, size `Visual/Cover` to cover the wall and the space behind it, set `breakable_from` to the side the player arrives from, and size `map_hides` over everything the map shouldn't show yet (the space behind, an exit to a hidden room).

## Known limitations

- Placeholder art: notches for climb walls, a blue bar for reveal platforms, coloured rectangles for the lever, gate and chest, a post and a square for the attack switch, a terrain-coloured rectangle for the secret wall. No sounds.
- No wall cling animation; the body just stops against the wall.
- A hit knocks the player off the wall into Hurt like anywhere else; there is no special fall-off reaction.
- Reveal platforms show all at once; they can't reveal one by one as the player walks across them.
- A lever pulled without its key gives no feedback yet.
- Chests, levers and switches have no map marks of their own; the player marks them by hand ([player marks](/systems/map#player-marks)).
