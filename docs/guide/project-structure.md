# Project structure

```
The-Last-Sich/
├── project.godot                 Engine settings, input map, autoloads, physics layers, version
├── CLAUDE.md                     Rules for AI-assisted work (docs, commits)
├── CHANGELOG.md                  Generated on release from commit messages
├── package.json                  Tooling: docs site, commit linting, releases (pnpm)
├── commitlint.config.ts          Commit message rules
├── lefthook.yml                  Git hooks
├── eslint.config.ts              Lint rules for the JS/TS tooling
├── mise.toml                     Pinned tool versions (Node, pnpm, gdtoolkit)
├── pnpm-workspace.yaml           pnpm settings (allowed install scripts)
├── .versionrc.json               Release and changelog settings
├── autoload/
│   ├── events.gd                 Global signal bus (autoload "Events")
│   ├── display_settings.gd       Fullscreen and scaling mode, saved to user://settings.cfg (autoload "DisplaySettings")
│   └── hit_stop.gd               Short game freeze on hits (autoload "HitStop")
├── components/
│   ├── state_machine/
│   │   ├── state_machine.gd      Generic finite state machine
│   │   └── state.gd              Base class for one state
│   ├── camera/
│   │   └── camera_shake.gd       Trauma-based shake for a Camera2D
│   ├── interaction/
│   │   └── interaction_area.gd   Touch or press-up area, base for exits and doors
│   └── combat/
│       ├── hitbox.gd             Deals damage while active
│       ├── hurtbox.gd            Detects hitboxes, reports hits, invincibility
│       ├── health.gd             Hit points, damaged and died signals
│       ├── invincibility_blink.gd   Blinks a visual while a hurtbox is invincible
│       └── hurt_feedback.gd      Flash, hit-stop and shake on every hit
├── actors/
│   ├── player/
│   │   ├── player.tscn           Player scene
│   │   ├── player.gd             Tuning values and shared helpers
│   │   ├── player_damage.gd      Hit reactions, hurt and death tuning
│   │   ├── abilities/            Movement pieces with their own tuning
│   │   │   ├── drop_through.gd   Down + jump through one-way platforms
│   │   │   └── ladder_climb.gd   Finds ladders to grab, climbing tuning
│   │   └── states/               One script per player state
│   │       ├── player_state.gd   Base class for player states
│   │       ├── idle.gd
│   │       ├── run.gd
│   │       ├── jump.gd
│   │       ├── fall.gd
│   │       ├── dash.gd
│   │       ├── climb.gd          On a ladder
│   │       ├── hurt.gd           Knockback after a hit
│   │       ├── dead.gd           Health ran out, waits, then asks for a respawn
│   │       └── attacks/          One script per attack direction
│   │           ├── player_attack_state.gd   Shared swing timing
│   │           ├── side_attack.gd
│   │           ├── up_attack.gd
│   │           └── crouch_attack.gd
│   ├── enemies/
│   │   ├── enemy.gd              Shared enemy base: tuning, movement and sensing helpers
│   │   ├── enemy_damage.gd       Enemy hit reactions, hurt and death tuning
│   │   ├── enemy_state.gd        Base class for enemy states
│   │   ├── states/               States shared by every enemy
│   │   │   ├── patrol.gd
│   │   │   ├── chase.gd
│   │   │   ├── hurt.gd
│   │   │   ├── dead.gd
│   │   │   └── enemy_attack_state.gd   Shared telegraphed attack timing
│   │   └── raider/
│   │       ├── raider.tscn       Melee grunt
│   │       └── states/
│   │           └── saber_slash.gd   Lunging forward cut
│   └── training_dummy/
│       ├── training_dummy.tscn   Stationary target for testing attacks
│       └── training_dummy.gd     Hit reaction, break and rebuild
├── levels/
│   ├── world.tscn                Main scene: player, HUD, screen fade and the current room
│   ├── world.gd                  Loads rooms, runs room transitions, respawns at rest points
│   ├── room.gd                   Base room logic: camera bounds, pits, respawning in the room
│   ├── objects/                  Things placed in rooms
│   │   ├── room_exit.gd          Edge exit or door to another room
│   │   ├── door.tscn             Door entered by pressing up
│   │   ├── rest_point.gd         Checkpoint: heal, reset enemies, set the respawn
│   │   ├── rest_point.tscn       Rest point scene
│   │   └── ladder.gd             Climbable ladder
│   ├── rooms/
│   │   ├── test_room.tscn        Test level (start room)
│   │   ├── test_cave.tscn        Second test room, east of the test room
│   │   ├── test_house.tscn       Small room behind the test room's door
│   │   └── test_shaft.tscn       Tall room under the test cave, reached through a hole
│   ├── terrain/
│   │   ├── terrain.tres          Shared tileset: solid and one-way tiles on the world layer
│   │   └── terrain_tiles.png     Placeholder tile texture (16×16 tiles)
├── ui/
│   ├── version_label.gd          On-screen game version
│   ├── screen_fade.gd            Black fade for room transitions
│   ├── hud/
│   │   ├── hud.tscn              Gameplay HUD layer, instanced in the world scene
│   │   └── health_bar.gd         Player health bar
│   └── debug/
│       └── debug_label.gd        On-screen state readout
├── tools/
│   ├── check_file_sizes.sh       Enforces file size limits
│   └── release/
│       └── godot-version-updater.ts   Bumps the version in project.godot
└── docs/                         This site (VitePress)
```

See [Code organization](/guide/code-organization) for the rules behind this layout and the planned folders.

## Folder rules

| Folder | What goes in it |
|---|---|
| `autoload/` | Global singletons registered in **Project Settings → Globals → Autoload**. Keep them few and small. |
| `components/` | Reusable building blocks with no knowledge of specific actors (state machine, hitboxes, hurtboxes, health). |
| `actors/` | Anything that moves and acts: the player, enemies, bosses, NPCs. One folder per actor, with its scene, script and states. |
| `levels/` | Rooms and level-specific scripts. |
| `ui/` | Menus, HUD and debug overlays. |
| `tools/` | Developer scripts that are not part of the game. |
| `docs/` | Documentation only. Ignored by Godot. |

Planned folders as the game grows: `assets/` (sprites, audio, fonts), `resources/` (data `.tres` files such as enemy stats), `actors/bosses/`.
