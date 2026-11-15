# Project structure

```
The-Last-Sich/
├── project.godot                 Engine settings, input map, autoloads, physics layers
├── CLAUDE.md                     Rules for AI-assisted work (docs, commits)
├── autoload/
│   └── events.gd                 Global signal bus (autoload "Events")
├── components/
│   └── state_machine/
│       ├── state_machine.gd      Generic finite state machine
│       └── state.gd              Base class for one state
├── actors/
│   └── player/
│       ├── player.tscn           Player scene
│       ├── player.gd             Tuning values and shared helpers
│       └── states/               One script per player state
│           ├── player_state.gd   Base class for player states
│           ├── idle.gd
│           ├── run.gd
│           ├── jump.gd
│           ├── fall.gd
│           └── dash.gd
├── levels/
│   ├── room.gd                   Base room logic
│   └── test_room.tscn            Test level (main scene)
├── ui/
│   └── debug/
│       └── debug_label.gd        On-screen state readout
├── tools/
│   └── check_file_sizes.sh       Enforces file size limits
└── docs/                         This site (VitePress)
```

See [Code organization](/guide/code-organization) for the rules behind this layout and the planned folders.

## Folder rules

| Folder | What goes in it |
|---|---|
| `autoload/` | Global singletons registered in **Project Settings → Globals → Autoload**. Keep them few and small. |
| `components/` | Reusable building blocks with no knowledge of specific actors (state machine, later hitboxes, health). |
| `actors/` | Anything that moves and acts: the player, enemies, bosses, NPCs. One folder per actor, with its scene, script and states. |
| `levels/` | Rooms and level-specific scripts. |
| `ui/` | Menus, HUD and debug overlays. |
| `tools/` | Developer scripts that are not part of the game. |
| `docs/` | Documentation only. Ignored by Godot. |

Planned folders as the game grows: `assets/` (sprites, audio, fonts), `resources/` (data `.tres` files such as enemy stats), `actors/enemies/`, `actors/bosses/`.
