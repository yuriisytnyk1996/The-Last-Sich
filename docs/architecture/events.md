# Events (signal bus)

`autoload/events.gd` is registered as the autoload **`Events`**. It holds signals that many unrelated systems care about.

## Why a signal bus

Without it, a kill zone would need a reference to the room, the HUD, the audio manager and the save system. With it, the kill zone emits one signal and every interested system subscribes on its own. Systems can be added or removed without touching the emitter.

## Signals

| Signal | Emitted by | Listened to by | Meaning |
|---|---|---|---|
| `camera_shake_requested(trauma)` | `HurtFeedback` (on every accepted hit) | `CameraShake` on the player's camera | Shake the active camera; `trauma` 0 to 1 adds up |
| `player_died` | `Room` (when the player enters the `KillZone`), the player's `Dead` state (after `death_delay`) | `Room` (respawns the player) | The player died and should respawn |

## Usage

```gdscript
# Emit
Events.player_died.emit()

# Listen
func _ready() -> void:
	Events.player_died.connect(_on_player_died)
```

## Rules

- Only put **global** events here. Signals between a parent and its own children should stay local (for example `StateMachine.state_changed`).
- Each signal is declared with `@warning_ignore("unused_signal")`, because it is emitted from other scripts.
- When you add a signal, add a row to the table above.
