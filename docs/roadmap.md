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

## Next

- [ ] Touch controls for mobile
- [ ] Attack state with hitbox and hurtbox components
- [ ] Health and damage
- [ ] Game feel: hit-stop and screen shake

## Later

- [ ] Pixel art sprites and animations for the player
- [ ] `TileMapLayer` terrain
- [ ] Room split into Layout / Deco / Logic sub-scenes
- [ ] Room transitions
- [ ] First enemy (reusing the state machine)
- [ ] Save system
- [ ] Audio
- [ ] Main menu and pause menu (with fullscreen and scaling mode options)

## Placeholders currently in the game

- Coloured rectangles for the player and platforms
- Debug label is always visible
