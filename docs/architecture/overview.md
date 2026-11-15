# Architecture overview

The game is built from three kinds of pieces:

| Piece | What it is | Example |
|---|---|---|
| **Autoloads** | Global nodes that exist for the whole game | `Events`, `DisplaySettings`, `SaveManager` |
| **Components** | Reusable nodes with no knowledge of who uses them | `StateMachine`, `State`, `Hitbox`, `Hurtbox`, `Health` |
| **Scenes** | Actors and levels assembled from nodes and components | `Player`, `TestRoom` |

## How the pieces connect

```
TestRoom (Room)
├── Platforms            static level geometry
├── KillZone ──────────► Health.kill() ──► Dead state ──► Events.player_died ──► Room respawns the player
├── SpawnPoint
├── TrainingDummy        Hurtbox + Health, target for testing attacks
├── Player (Player)
│   ├── Visual           placeholder graphics, flipped to face left/right
│   │   └── Attacks      one hitbox per attack direction
│   ├── Camera2D         limited to the room's bounds
│   └── StateMachine
│       ├── Idle
│       ├── Run
│       ├── Jump
│       ├── Fall
│       ├── Dash
│       └── SideAttack, UpAttack, CrouchAttack
└── DebugLayer
    └── DebugLabel       reads the player's current state
```

## Core principles

**Small scripts with one job.** `player.gd` holds tuning values and helper functions. Each state script holds one behaviour. Adding a new move means adding one new state script, not growing a giant `if` chain.

**Data in the Inspector.** All tuning values are `@export` variables, so movement can be tuned by feel in the editor.

**Loose coupling through signals.** A kill zone doesn't know what happens when the player dies; it only announces it. The room, and later the HUD, audio and save system, react independently. See [Events](/architecture/events).

**Processing order is deliberate.** Godot runs `_physics_process` on a parent before its children. `Player` updates its timers (coyote time, jump and attack buffers, dash cooldown) first, then its `StateMachine` child runs the current state with fresh values.

## Frame flow (physics tick)

1. `Player._physics_process` updates the timers and reads the jump and attack presses into their buffers.
2. `StateMachine._physics_process` calls `physics_update` on the current state.
3. The state changes `velocity`, calls `move_and_slide()`, then checks its exit conditions.
4. If a condition is met, the state emits `finished("NextState")` and the machine switches immediately. The new state starts running on the next tick.
