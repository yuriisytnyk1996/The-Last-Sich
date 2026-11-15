# Roadmap

## Done

- [x] Project settings for pixel art (640×360, integer scaling, nearest filtering, pixel snapping)
- [x] Renderers: Forward+ on desktop, Mobile on phones, 2D HDR
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
- [x] Display settings: fullscreen by default (F11 / Alt+Enter) and scaling mode (pixel perfect / scale, F3 in debug builds), saved between runs
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
- [x] Doors you enter by pressing up, `InteractionArea` base, arrival facing for exits
- [x] Vertical exits: fall through a floor hole into the room below, jump up through a ceiling opening with a launch (`arrival_rise`); test shaft under the cave

## Next

- [ ] Ladders
- [ ] Rest points: checkpoint that heals, resets enemies and sets the respawn
- [ ] Enemy poise, so a lone enemy can't be kept staggered forever

## Later

- [ ] Enemy line of sight (walls block vision)
- [ ] Pixel art sprites and animations for the player and the raider
- [ ] Terrain tile art with autotiling
- [ ] Room split into Layout / Deco / Logic sub-scenes
- [ ] Save system
- [ ] Upgrade system, then upgrade attacks: combos, charged attack, dash attack, dive attack
- [ ] Audio
- [ ] Main menu and pause menu (with fullscreen and scaling mode options)

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
- Plain rectangles for the HUD health bar
- Brown rectangle for doors, a triangle for the press-up prompt
- Coloured rectangles for the raider, a yellow rectangle for its attack telegraph and a translucent rectangle for its slash
