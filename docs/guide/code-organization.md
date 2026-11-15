# Code organization

How files and folders are organized so any script is quick to find and easy to read in one sitting. These rules follow how large shipped 2D action games keep thousands of scripts manageable.

## The numbers we aim for

Large production codebases are made of many **small** files. In a typical shipped 2D action game with around 5,000 scripts:

| Measure | Typical value |
|---|---|
| Median file length | ~35 lines |
| 75% of files | under ~75 lines |
| 90% of files | under ~150 lines |
| Files over 800 lines | under 1% |
| Files per folder | median 2, 90% have 7 or fewer |

The few giant files (thousands of lines, usually boss logic or menus) are the hardest parts of those codebases to read and change. We avoid them from the start.

## File size limits

| Lines | Status |
|---|---|
| up to 100 | Target for most scripts |
| 101–200 | Fine for central scripts (actor root, managers) |
| 201–300 | Warning: plan a split |
| over 300 | Not allowed: split before committing |

Check with:

```sh
tools/check_file_sizes.sh
```

Functions should fit on one screen (about 30 lines). If a function needs comments to separate its sections, those sections are separate functions.

## Folder hierarchy

Organize **by feature, then by concern**. Everything about one actor lives in that actor's folder. Inside it, code is split by what it does.

```
res://
├── autoload/                 Global managers, one per file
│   ├── events.gd
│   └── (save_manager.gd, audio_manager.gd, ...)
├── components/               Reusable, actor-agnostic building blocks
│   ├── state_machine/
│   └── combat/               Hitbox, hurtbox, health
├── actors/
│   ├── player/
│   │   ├── player.tscn
│   │   ├── player.gd         Data and shared helpers only
│   │   ├── states/           One behaviour per file
│   │   └── (abilities/, attacks/, audio/)
│   ├── enemies/
│   │   ├── enemy.gd          Shared enemy base class
│   │   └── <enemy_name>/     Same layout as player/
│   └── bosses/
│       └── <boss_name>/
│           ├── <boss>.gd
│           └── states/       One file per attack pattern
├── levels/
│   ├── room.gd
│   └── (rooms/<area>/<room>.tscn)
├── ui/
│   ├── (hud/, menus/)
│   └── debug/
├── (assets/)                 sprites/, audio/, fonts/, mirroring the code folders
├── (resources/)              Data files (.tres): stats, item definitions
└── tools/                    Developer scripts, not part of the game
```

Folders in parentheses are planned and are created when the first file needs them. Empty placeholder folders are not created.

## Rules

### One class per file

The file is named after its class in `snake_case`: `class_name StateMachine` → `state_machine.gd`. Scenes share the name of their root script: `player.tscn` + `player.gd`.

### Same layout for every actor

Every actor (player, enemy, boss, NPC) uses the same structure: a root scene and script, a `states/` folder, and optional `attacks/`, `abilities/` and `audio/` folders. Once you know one actor, you can navigate them all.

### Split by concern, not by size alone

An actor's root script holds **data and small helpers**. Behaviour goes into states. Reusable pieces (health, hitboxes, sensors) go into `components/` and are added as child nodes. If you're about to add a second responsibility to a script, it belongs in a new file.

### Bosses: one attack pattern per file

Boss logic is where codebases most often end up with single files of several thousand lines. Each attack pattern is its own state script under the boss's `states/` folder. The boss root script only holds tuning values and helpers, and a phase controller decides which pattern runs next.

### Small folders

When a folder grows past about 10 files, group them into subfolders by concern. Keep nesting at most 4 levels below `res://`. Deeper paths are hard to navigate.

### Shared code goes up, never sideways

When two actors need the same code, move it to a base class (`actors/enemies/enemy.gd`) or a component (`components/`). Never import one actor's scripts from another actor's folder.

### No dumping grounds

No `utils.gd`, `helpers.gd` or `misc/` folders. Every function belongs to the system it serves. Truly global helpers go in a named autoload with a clear purpose.

## When a file gets too big

1. Look for groups of functions that work on the same variables. Each group is a candidate component or state.
2. Move behaviour out of the actor root script into states.
3. Move data (stats, tables, curves) into `.tres` resources under `resources/`.
4. Update the docs page for the system and [Project structure](/guide/project-structure).
