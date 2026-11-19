# Roadmap

## Done

- [x] Project settings for pixel art (640×360, integer scaling, nearest filtering, pixel snapping)
- [x] Renderers: Forward+ on desktop, Mobile on phones, 2D HDR
- [x] Physics interpolation: smooth motion on 120 Hz+ screens
- [x] Input map for keyboard and gamepad
- [x] `Events` signal bus
- [x] Reusable state machine
- [x] Player movement: run, jump, fall, dash, coyote time, jump buffer, variable jump height
- [x] Test room with camera bounds, kill zone and respawn
- [x] Debug state label
- [x] Documentation site
- [x] Code organization rules and file size check
- [x] Conventional Commits, git hooks, automated versioning and changelog
- [x] In-game version label
- [x] Linting and formatting: ESLint for TS tooling, gdtoolkit for GDScript, pinned tools via mise
- [x] Project `code-style` skill for AI-assisted refactoring
- [x] Display settings: fullscreen by default (F11 / Alt+Enter) and scaling mode (pixel perfect / scale), saved between runs
- [x] Combat components: `Hitbox`, `Hurtbox`, `Health`
- [x] Player attack state with startup / active / recovery windows and attack buffering
- [x] Directional attacks: side, up and crouch. Planted on the ground (can turn mid-swing), air control in the air, re-swing after a miss
- [x] Training dummy in the test room
- [x] Player health, hurtbox, hurt state with knockback, invincibility with blinking, death and respawn
- [x] Continuous hitboxes for hazards (re-hit after invincibility), spikes in the test room
- [x] Game feel: hit-stop, camera shake and hit flash on every hit (`HitStop`, `CameraShake`, `HurtFeedback`)
- [x] Hit reactions: light, normal and heavy hitboxes
- [x] Player invincibility lasts through the stagger plus a short window after it
- [x] HUD health bar: instant fill drop, trailing loss segment, width grows with max health, driven by `Events.player_health_changed`
- [x] Bottomless pits are instant death: the kill zone empties health and the player goes through the Dead state before respawning
- [x] Enemy base: shared `Enemy` class, `EnemyDamage`, and shared Patrol, Chase, Hurt and Dead states
- [x] Telegraphed enemy attacks (`EnemyAttackState`): interruptible wind-up, committed once the hitbox is out, cooldown
- [x] First enemy: the raider, a melee grunt with a lunging saber slash and contact damage
- [x] Enemies reset when the player respawns; pits kill enemies too
- [x] Room transitions: `World` main scene owns the player and HUD, `RoomExit` doorways at screen edges, fade out and in while the game is paused, health carries over, death respawns at the room's entrance
- [x] `TileMapLayer` terrain: shared 16×16 tileset with solid and one-way tiles, test room rebuilt on the tile grid with every platform in jump reach
- [x] Drop through one-way platforms with down + jump
- [x] Doors you enter by pressing a button, `InteractionArea` base, arrival facing for exits
- [x] Vertical exits: fall through a floor hole into the room below, jump up through a ceiling opening with a launch (`arrival_rise`); test shaft under the cave
- [x] Ladders: grab with up or down, climb, jump off, climb through vertical exits into another room
- [x] Rest points: press interact to heal and reset the room's enemies; death respawns at the last one used, loading its room
- [x] Hard landing: falling 10 tiles or more leaves the player stuck in place for a moment, with a camera shake; a dash cancels it halfway
- [x] Enemy poise: after 3 staggers in a row an enemy stops flinching and strikes back
- [x] Save system: the last rest point is saved to disk on rest and loaded on start; rooms and global systems can save their own state; safe writes with a backup; F8 deletes the save in debug builds
- [x] Enemy line of sight: walls block vision, the player is noticed behind an enemy at close range, and a chase ends after losing sight for a moment
- [x] Enemies don't run at a player they can't reach (another level, wall or ledge in the way): they stop, watch, then turn away and patrol; turning is throttled so they don't flip under the player
- [x] Healing flasks: a few charges that heal on the ground while standing still, refilled at rest points and on death, shown as pips in the HUD; aura while drinking, HUD flash on use and shake when empty
- [x] One key and one gamepad button per action; a separate interact button (E / B) for doors and rest points instead of up
- [x] Main menu (Continue / New game / Options / Quit) as the main scene, and a pause menu (Escape / Start) with Resume, Options and Quit to main menu
- [x] Options, applied and saved at once: video (fullscreen, resolution, scaling, VSync, textures, brightness, 10 CRT filter presets), audio (master, music, effects and voice buses), accessibility (screen shake, rumble) and controls (rebind keys and gamepad buttons, swap on conflict, reset to defaults)
- [x] Gamepad rumble on hits
- [x] Rooms split into Deco, Layout and Logic sub-scenes, so art and level design can be edited apart
- [x] Killed enemies stay dead across room changes until the player rests or dies (`stays_dead` to opt out)
- [x] Parry and riposte: a timed guard deflects parryable melee swings and stuns the attacker, then attack within a short window for an invincible heavy counter-slash; a mistimed guard leaves the player open
- [x] Currency: enemies give currency on death, shown in the HUD and saved
- [x] Spirit: a resource filled by landing hits (double for heavy hits), shown as a bar under health; empty on load, not refilled by resting
- [x] Death penalty: every death leaves a death mark (up to 5) on the last safe ground; each lowers max spirit, spirit gain and currency gain; marks left close together link; press interact at a mark to recover it and its links, healing a third of max health and half of max spirit; the game saves on death
- [x] Spikes kill instantly when stepped in, but never when only brushed mid-jump
- [x] Ledge grab: falling past a wall top while facing it hangs from the ledge; up or jump climbs onto it, down lets go. Works on any solid tile corner with room on top
- [x] Ladder grab fixes: a jump off a ladder blocks grabbing only until it peaks (holding up then jump catches the ladder at the top of the jump), ladders hanging in the air are caught by the upper body, and a lighter push grabs in the air
- [x] Skills: upgrades learned at a skill shrine with currency, each with a tier, a cost and a parent skill; learned skills are saved
- [x] Ground combo: side swings that hit chain into more swings and a heavy swing; skills add a forward, a rising (up) and a slam (down) finisher
- [x] Full skill tree: five lines of three levels (combo, charged slash, lunge, dive, ranged bolt), tiers that gate the stronger levels, tier relics that raise the tier
- [x] Charged slash: hold attack after a ground slash, let go when charged; faster charge, then a ground wave
- [x] Lunge: attack during a dash for a thrust that runs through enemies; faster, longer and stronger per level
- [x] Dive: down + hold attack in the air to plunge and hit around the landing; wider landing, then a shockwave from high up
- [x] Ranged bolt: a new `ranged` button throws a bolt for spirit; it returns, then bursts at the turn
- [x] World map: rooms placed on a grid of map cells, cells revealed as the player walks through them and saved; walls with door gaps from room exits, zone colours, marks for rest points, shrines, inner doors and death marks; opened from the pause menu or with M / Back, pan and two zoom levels
- [x] Second enemy, the musketeer: closes in to musket range and plants itself (never backs away), fires only when it can aim at the player, aims with a visible aim line that freezes just before the shot, fires a musket ball that can't be parried, then a long reload. Shared `EnemyProjectile` for enemy shots
- [x] Environment pieces: breakable crates and cracked walls (stay broken, saved; props fill no spirit), moving platforms (one-way or solid), elevators with call levers, timed spike and fire traps, turrets, and wind, mud and poison zones. New test works room east of the test cave
- [x] Stats: named player stats (max health, flasks, damage, per-element resistances, spirit, parry and riposte windows, dash cooldown) with flat and percent modifiers added and removed by source, plus timed modifiers. Health, Flasks, Spirit, Parry, the dash and every player hitbox read from them. Hits carry an element (normal, contact, fire, poison)
- [x] Health and damage on a 100-point scale (player 100, basic hit 20, raider 60, musketeer 40); enemies have their own stats (health, damage multiplier, resistances)
- [x] Inventory: items made of effects (stat modifiers or a one-time restore) set off while carried, while worn, on a hit, on a kill or on being hurt, with an optional low-health condition, chance and duration. Charms in slots (a stat, raised by pouches), one blade with a trade-off, keepsakes that work while carried. Item pickups in rooms, an inventory page (tabs per kind, worn row with locked slots, item grid, details panel; I to open), a HUD toast for new items, saved. 15 items
- [x] Shops: stands that sell one item each for currency, a buy page with the price and the player's currency, sold stands stay empty (saved), shop marks on the map. Test shop in the test house

- [x] Ability-gated traversal: unlocks given by items (`UnlockEffect`); wall cling (hold attack in the air facing a marked climb wall) and wall jump, a basic move from the start; reveal platforms shown by the seer's lantern, a relic (new item kind, 3 slots, worn from the inventory); levers that toggle or unlock gates (one-shot shortcuts, key-locked levers, locked gates); chests with an item and currency; hidden areas behind false walls that fade when entered. All saved. New test vault room east of the test works
- [x] Death marks never land on ground that comes and goes: crumbling, timed and reveal platforms never count as safe ground; moving platforms and elevators only when `safe_ground` is on, and only while they wait
- [x] Paid cleanse points: pay currency (a price per mark) to clear every death mark at once without walking back, no recovery bonus; map mark; one in the test house
- [x] Secret walls: drawn like the terrain, broken with attacks (3 hits) from one side only, flash on every hit, then fade to show the secret behind; hits taken are saved. Breakables gain `breakable_from` and `fade_time`. Replaces the walk-in hidden areas
- [x] Upgrades: permanent +20 max health and +15 max spirit from upgrade shrines, used once; free ones hidden as secrets, paid ones with a page to pay currency; the raised bar fills, a HUD toast names it, saved; paid shrines on the map. A health shrine in the test vault's hidden alcove, a spirit shrine in the test house
- [x] Map secrets and player marks: a secret (`Breakable.map_hides`) keeps the cells, door gaps and marks behind it off the map until it breaks; the current room is scanned again before it unloads, when the map opens and on save. The player places their own marks on visited cells (chest, question, enemy, person, three pins; one per cell; attack on the map page), saved. A hidden test hideout room behind the vault's secret wall
- [x] Travel between rest points: with the Chumak's whip (keepsake, test house shop), resting makes the player kneel and offers the travel map; the cursor hops between found rest points (cone search, eased glide, pulsing cursor) and attack travels there with a fade, making it the respawn point. Second rest point in the test cave. Kneeling is a player state: the heal fills the HUD before the prompt pauses the game
- [x] Spirit at rest points: the Icon lamp (keepsake, test house shop) makes resting fill spirit and death respawn it full; without it, death now empties spirit. Spirit still starts empty on load
- [x] Attack speed, run speed and critical hits as stats: attack speed shortens swing startup and recovery, run speed drives running, crit chance and crit damage roll per hit with a gold flash and stronger feedback. Three charms (hare foot, quick bracer, raven eye) in the test room
- [x] Pressure plates: pressed by the player or an enemy standing on them; `HOLD` keeps gates open while pressed (with an optional close delay for timed gates), `LATCH` opens them for good (saved). Two test plates in the test hideout
- [x] Map completion: the map page shows the percentage of the world's cells explored, counted against a generated map catalog of every room (`pnpm map:catalog`, checked by the pre-commit hook)
- [x] Item lore: every item has a lore text, read on a lore page opened with R / Y from the inventory.

- [x] Three more enemies: the shieldbearer (a raised shield blocks hits from the front; heavy hits break the guard, hits from behind land), the boar (charges in a straight line once it can see the player, crashes into walls and is dazed, stops at ledges) and the crow (flies, hovers above the player and swoops at it, loses it under cover). New `Hurtbox.guard` for blocking, `attack_needs_sight` on enemies, and a test barracks room behind a second door in the test room

- [x] Bosses: a `Boss` base with phases at health thresholds (faster timings, new attacks), shared Dormant, Roar and Decide states, weighted `BossAttack`s picked by range and phase, no flinching but parries still stun; `BossArena` closes its gates when the player walks in, reopens them on a win or a death, gives an item and saves the win; a boss bar in the HUD. First boss, the Otaman: three-swing sabre combo (last swing parryable), leap slam with floor shockwaves, dash cut, and a pistol volley in phase 2. Test arena behind the test barracks' east door

- [x] Guard slide: a HEAVY hit caught on the parry guard deals no damage and slides the player back (distance from the hit's force), invincible, facing the attacker; a held dash at the end of the slide cancels into a dash towards the attacker. New `guard_slide` and `unblockable` hitbox flags, `guard_slid` signals for attacks that should react. Works on the Otaman's slam and dash cut and the boar's gore

- [x] Dumas: songs sung for spirit, a new item kind with one slot and a `duma` button (Q / left trigger, triggers can now be bound). A planted cast with an aura spends the cost at the cast point, then the duma's `ON_USE` effects run; while a lasting one runs, no other can be sung and a line under the spirit bar shows its time left; the bar flashes when spirit is short. `duma_cost`, `duma_duration` and `duma_strength` stats. Seven dumas: pillars of fire forward, pillars on both sides, a thunderbolt, a three-shot volley, a stunning burst (new `Hitbox.stuns`), a ring of sabres that cuts enemies and destroys their shots, and heavy strikes. All in the test room

- [x] Flask upgrades: empty flasks found in rooms add a flask for good (empty until the next rest); a flask healer makes every flask heal 10 more for a vial of living water and a rising price, five levels, shown by the colour of the HUD flask pips. Base flask heal lowered to 20. Drinking at full health is allowed and wastes the flask; a light hit now ends the drink too. New quest item kind (`Item.Kind.QUEST`, a tab on the inventory page) for items handed over, and `PlayerInventory.remove()`. Healers get the upgrade mark on the map. Test healer in the test house, two empty flasks and two vials in the test barracks

- [x] Executions: a lethal hit on a stunned enemy (a riposte, a stunning duma) or a lethal heavy hit that catches it winding up (or any lethal heavy hit once a random kill counter, 3 to 6 kills, runs out) leaves it on its knees at 1 health instead of killing it; an awareness mark flashes, and interact plays an invincible finisher that kills it and gives spirit. Left alone it gets up with half its health; any hit after a short safe time just kills it. Fake executions: the same finisher placed in a room with no enemy behind it, for scripted kills, saved once done. `Health.spare_next_lethal`, `Events.enemy_executed`. Raider, musketeer, shieldbearer and boar can be executed; a fake one in the test barracks

- [x] Attack switches: a switch hit with any player attack (the ranged bolt too, for switches out of reach) drives gates like a lever: `TOGGLE`, `UNLOCK`, or `TIMED` (opens for a few seconds, owns its targets), optionally one-shot; fills no spirit, saved. A one-shot switch opens a new corridor gate in the test hideout

- [x] Soft landing: the owl feather relic (`soft_landing` unlock, while worn) removes hard landings. In the test room. It has the first real item icon (`assets/sprites/items/owl_feather.png`)
- [x] Charm icons: all 12 charms have 16×16 pixel-art icons in `assets/sprites/items/`
- [x] Crumbling platforms: shake under the player, then give way, dropping (collapsing) or fading in place (vanishing), and come back after a while or only when the room reloads. Vanishing stairs and a collapsing bridge in the test shaft
- [x] Ledge grab only grabs terrain tiles, never gates, crates, cracked walls or moving bodies
- [x] Save slots: three slots; the title screen's Continue loads the latest one and Play opens a slot list (zone, play time, map explored, currency per slot); an empty slot starts a new game, a taken one continues or is deleted (asked first); old or damaged saves show as such and can be replaced. A new game saves at once; play time is counted and saved
- [x] Object pooling: projectiles and blasts are taken from and parked back in a `Pool` autoload instead of being instantiated and freed, with prewarmed instances so the first shot of a fight doesn't stall. See [Object pooling](/architecture/object-pooling)
- [x] Timed platform sequences: platforms that appear one step after another on a loop, blink before they vanish and fade out from under the player; one clock per sequence. A six-step climb to a ledge in the test shaft
- [x] More environment pieces: drip traps (a ceiling spout swells a drop of burning tar, then lets it fall), ghost traps (a haunted spot where loose pages flutter up around the moving player, for show; pooled) and shockwave areas (floor bands that tremble, then strike with a HEAVY hit that jumping or a plank avoids and the guard slides). The Duma of the Road Home takes the player back to the last rest point without healing, not during a boss fight (new `ItemEffect.can_start()`). New test crypt room west of the test house
- [x] NPCs, dialogue and quests: story flags and counters (`PlayerStory`, saved at once by `StoryAutosave`), conditions on flags, counters and items (carried, any of, ever obtained, counted sets), outcomes that set flags, raise counters, hand items and currency over, turn in collectibles and show a message; conversations with answers in a typed text box that pauses the game; NPCs that pick a conversation by condition and come or go with the story; `StoryTrigger` (room events such as a broken cage, a picked-up item, a beaten boss or a reached place move quests on) and `StoryToggle` (chests appear, gates open by a condition); levers say which key they need and can use it up. Test content for every quest type: the kobzar's string (hand-in, hint, failure if the Otaman dies first, a chest afterwards), the elder (three captive cages, three Sich letters to turn in, news of the Otaman) and the alms box in the crypt (donation tiers)
- [x] Tips: "how to play" cards (`Tip`, one `.tres` each) that pause the game the first time something comes up: the first finisher, the first and second death, the first charm, blade and relic found, the first duma worn, the first captive freed (a `StoryOutcome.tip`, so conversations and room events can show tips too), and `TipArea`s placed in rooms (parry and healing in the test room). Each shows once per slot (`TipLog`, saved), waits while the game is paused, names the current key or button for each action and switches when the player changes device, fades in and out over the paused game, has room for a picture, can be reread from Pause > Tips and turned off in Options > Accessibility
- [x] Cutscenes and scripted control: a `Cutscene` in a room takes the player's control (`Scripted` state, can't be hurt), hides the HUD behind letterbox bars, freezes the room's enemies (or not, for an ambush) and plays steps one after another or side by side: walk the player, glide the camera to a marker and back (`CameraDirector`, within the room's limits), conversations, calls on room nodes (open a gate), moving an NPC, story outcomes, title cards, quotes over a black fade, fades, shakes, waits. Starts on entering the room, from a walk-in or interact trigger, from a signal, or from a script; plays once with a flag. Pause twice skips: under a black fade every remaining step jumps to its end. Boss intros (`BossArena.intro`): the Otaman's name and a camera glide before the fight. New test kurgan room behind the test barracks' east door, with an arrival, an ambush and a vigil at a stone idol, and the Grave keeper NPC. See [Cutscenes](/systems/cutscenes)
- [x] Even frame pacing: without VSync the frame rate is capped at the screen's refresh rate, and VSync is off by default on macOS, where the engine's VSync missed about one refresh in eight on 120 Hz screens. See [Frame pacing](/systems/rendering#frame-pacing)
- [x] Localization: gettext translations with English text as the key. Every menu, HUD, card and dialogue string goes through `tr()`; the Text Extractor editor plugin adds the game's own resources and node properties (dialogue, tips, items, skills, NPC and boss names, zones, cutscene cards) to POT generation; `pnpm i18n:files` keeps the template's file list complete. Options > Language (English, Ukrainian) is saved in `settings.cfg`, starts from the system language, and redraws open menus at once. See [Localization](/systems/localization)

- [x] Debug console: F1 in debug builds opens a command line over the paused game, with history, Tab completion of names and arguments, and commands for god mode, healing, currency, items, skills, upgrades, moving between rooms, killing the room's enemies, story flags and counters, revealing the map, clearing death marks, forgetting tips, saving and the game speed. See [Debug console](/systems/debug-console)

- [x] Companions and summon dumas: `SummonEffect` helpers in `actors/player/companions/` (`Companion` base). The Duma of the Wagon Fort sets down a warding circle where no hit lands on the player (new `Hurtbox.set_ward()`, enemy shots stop on a ward); the Duma of the Sworn Brother summons a ghost that lunges with a HEAVY cut when the player swings and shields them when they parry; the Duma of the Falcons sends three falcons, one at a time, at the nearest visible enemy and ends when the last one flies. The wandering candle, a relic, summons a light that follows the player and leads to captives still caged in the room (cages join the `captives` group). Dumas in the test room, the candle in the test barracks. See [Dumas](/systems/dumas#companions)

## Next

Nothing picked yet. The next item comes from Later.

## Later

- [ ] Pixel art sprites and animations for the player and the raider
- [ ] Terrain tile art with autotiling
- [ ] Audio
- [ ] Map: items that reveal a zone
- [ ] Hand-placed ledge markers, when real levels need them: an optional marker on a wall that turns automatic ledge detection off there, or forces a grab where detection wouldn't find one

## Last

The game is built and tuned on desktop first. Mobile comes at the end.

- [ ] Touch controls for mobile

## Placeholders currently in the game

- Coloured rectangle for the player
- Flat-colour terrain tiles (solid block and one-way plank)
- Debug label is always visible
- Translucent rectangle for the attack slash
- Coloured rectangles for the training dummy and its health bar
- Red rectangle for the spikes
- Dark tint for the dead player instead of a death animation
- Plain rectangles for the HUD health bar and flask pips
- Flat-colour cells, walls and square marks on the world map, 5×5 pixel icons for player marks
- Translucent rectangle for the healing aura instead of a drinking animation
- Drawn rails and rungs for ladders
- Post, crossbar and flame rectangles for rest points
- Brown rectangle for doors, a triangle for the interact prompt
- Default engine font and plain coloured rows for the menus, no menu art or sounds
- Coloured rectangles for the raider, a yellow rectangle for its attack telegraph and a translucent rectangle for its slash
- Grey basin with a pale strip for the cleanse point
- Coloured rectangles for NPCs (a polygon kobza for the kobzar, a mace for the elder), a grey box for the alms box, bars over a rectangle for captive cages, a bordered box with the default font for dialogue, no portraits or text sounds
- Drawn shapes with a letter for item icons (a lantern for relics), except the owl feather and the charms
- Orange gourd for empty flasks, a brown table with a bowl and a flask for the flask healer, a vial shape for quest item icons
- Purple post for death marks, plain bars and pips for spirit and death marks in the HUD, a plain number in the default font for the HUD currency
- No hang or climb-up animation for ledges, the placeholder body just moves
- Grey rectangles with a blue gem for the skill shrine, blue diamonds for tier relics, plain text cells for the skill menu, coloured rectangles for the combo, charged, lunge and dive hitboxes, the projectiles and the blasts, a bar above the head for a full charge
- Coloured rectangles for the musketeer and its barrel, a thin line for its aim, a small rectangle for the musket ball
- Coloured rectangles for the shieldbearer, its shield and the block flash, the boar and the crow, and for their thrust, gore and talon hitboxes
- Brown boxes for crates, a grey block with a dark line for the cracked wall, no break debris
- Flat rectangles for moving platforms, elevators and their levers, a cracked rectangle for crumbling platforms
- Polygon spikes, a flame rectangle and small glowing warning rectangles for timed traps; grey boxes for turrets and red rectangles for their bolts
- Drawn tints for zones and drifting line streaks for wind
- Notches for climb walls, blue bars for reveal platforms, coloured rectangles for levers, pressure plates, gates and chests, a post and a square for attack switches, a terrain-coloured rectangle for the secret wall; no wall cling animation
- Coloured rectangles for the Otaman, its swings, slam, dash, shockwaves and pistol balls, a red bar over its head for the roar; plain bar and default-font name for the boss bar
- Translucent rectangles for the Sworn Brother, his cut and his shield, small brown rectangles for falcons, a pale gold half-disc for the Wagon Fort, a two-rectangle flame for the wandering light
- Blue glow for the duma aura, coloured rectangles for the fire pillars, thunder beam, stun burst, duma shots and the sabres, a thin line under the spirit bar for a running duma, a scroll shape for duma icons
- A brown spout and an orange bead for drip traps, a dark rectangle for the drop; small pale rectangles for ghost pages and a faint violet tint for ghost traps; an orange tint that flickers and flashes for shockwave areas
- Black rectangles for the letterbox bars, the default font for title cards, quotes and the skip prompt; no walking animation for the scripted walk, a gliding NPC for `MoveStep`; a coloured rectangle with a hood and a spade for the Grave keeper, a grey polygon with two orange pixels for the kurgan's stone idol, polygon grave crosses and hills for the kurgan backdrop
- A squashed body for a kneeling enemy, a red exclamation mark for the execution awareness, a gold bar and rectangle for the finisher
- Blue bar for the parry guard (flashed and slid along for a guard slide), a bar above the head for a stunned enemy, a gold rectangle for the riposte slash
