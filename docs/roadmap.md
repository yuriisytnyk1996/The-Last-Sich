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

## Next

- [ ] Touch controls for mobile

## Later

- [ ] Pixel art sprites and animations for the player
- [ ] `TileMapLayer` terrain
- [ ] Room split into Layout / Deco / Logic sub-scenes
- [ ] Room transitions
- [ ] First enemy (reusing the state machine)
- [ ] Save system
- [ ] Upgrade system, then upgrade attacks: combos, charged attack, dash attack, dive attack
- [ ] Audio
- [ ] Main menu and pause menu (with fullscreen and scaling mode options)

## Placeholders currently in the game

- Coloured rectangles for the player and platforms
- Debug label is always visible
- Translucent rectangle for the attack slash
- Coloured rectangles for the training dummy and its health bar
- Red rectangle for the spikes
- Dark tint for the dead player instead of a death animation
- Plain rectangles for the HUD health bar
