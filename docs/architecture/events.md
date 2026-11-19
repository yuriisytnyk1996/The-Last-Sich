# Events (signal bus)

`autoload/events.gd` is registered as the autoload **`Events`**. It holds signals that many unrelated systems care about.

## Why a signal bus

Without it, a kill zone would need a reference to the room, the HUD, the audio manager and the save system. With it, the kill zone emits one signal and every interested system subscribes on its own. Systems can be added or removed without touching the emitter.

## Signals

| Signal | Emitted by | Listened to by | Meaning |
|---|---|---|---|
| `camera_shake_requested(trauma)` | `HurtFeedback` (on every accepted hit) | `CameraShake` on the player's camera | Shake the active camera; `trauma` 0 to 1 adds up |
| `player_health_changed(current, maximum)` | `PlayerDamage` (on every health change, and once on spawn) | `HealthBar` in the HUD, every `Enemy` (to know whether the player is alive) | The player's health is now `current` out of `maximum` |
| `player_flasks_changed(current, maximum, level)` | `PlayerFlasks` (on drinking, on refill, on a flask upgrade, and once on spawn) | `FlaskCounter` in the HUD | The player has `current` healing flasks out of `maximum`, at flask healing `level` |
| `player_flasks_empty` | `PlayerFlasks` (heal pressed with no flasks left) | `FlaskCounter` in the HUD | Show that there is nothing to drink |
| `player_died` | The player's `Dead` state (after `death_delay`; pits kill through `Health.kill()` and end up here too) | `World` (respawns at the last [rest point](/systems/rest-points), or asks the current `Room` to respawn the player and reset its enemies), `TipLog` (the death tips) | The player died and should respawn |
| `enemy_killed` | `EnemyDamage` (an enemy died, not one restored as already dead) | `PlayerItemEffects` (`ON_KILL` item effects) | An enemy was killed |
| `enemy_executed` | `PlayerExecutions.reward()` (the finishing blow of an [execution](/systems/combat#executions)) | Nothing yet | The player executed an enemy or a fake execution |
| `story_changed(flag)` | `PlayerStory` (a flag set or cleared, a counter raised; empty `flag` after loading) | `Npc`, `StoryToggle`, `StoryAutosave` | The story moved on, see [NPCs, dialogue and quests](/systems/story) |
| `message_shown(text)` | `StoryOutcome` (its `message`), `Lever` (a missing key) | `ItemToast` in the HUD | Show a short line at the bottom of the screen |
| `item_obtained(item)` | `PlayerInventory.add()` | `ItemToast` in the HUD, `TipLog` (first item of a kind) | The player got `item` |
| `tip_requested(tip)` | `Execution` (a finisher appeared), `TipArea` (the player walked in), `StoryOutcome` (its `tip`) | `TipLog` (shows it once the game runs, unless seen or tips are off) | Show a "how to play" card, see [Tips](/systems/tips) |
| `player_unlocks_changed` | `PlayerUnlocks` (an unlock gained or lost) | `RevealPlatform` | The player's traversal unlocks changed, see [Traversal](/systems/traversal#unlocks) |
| `rested(rest_point)` | `RestPoint` (the player pressed up at it) | `World` (remembers it as the respawn point and saves the game), every `RestPoint` (lights the used one) | The player rested; `rest_point` is the node |
| `return_requested` | `ReturnEffect` (the [Duma of the Road Home](/systems/dumas#dumas) was sung) | `World` (fades out and puts the player back at the last rest point, without healing) | Take the player back to the last rest point used |
| `room_change_requested(room_path, exit_name)` | `RoomExit` (the player touched it, or pressed up at a door) | `World` (fades out, swaps the room, fades in) | Load `room_path` and place the player at its exit named `exit_name` |
| `player_arrived` | `World`, behind the black screen of every transition (a room exit, travel, the Road Home, a respawn), once the player is placed | `WagonFort` (opens again at the player's feet) | The player is somewhere new; things left on the spot that should come along move there |
| `cutscene_started(letterbox)` | `Cutscene` (it took the player's control) | `CinematicBars` (hides the HUD, slides the bars in when `letterbox`) | A [cutscene](/systems/cutscenes) started |
| `cutscene_ended` | `Cutscene` (control handed back, played out or skipped) | `CinematicBars` (bars out, HUD back), the cutscene cards (hide), every `CutsceneTrigger` (prompt) | The cutscene ended |
| `cutscene_skipped` | `Cutscene` (a skip, once the screen is black) | `TitleCard`, `QuoteCard`, `SkipPrompt` (hide at once) | The player skipped the cutscene |
| `cutscene_skip_offered(binding, time)` | `Cutscene` (first press of pause) | `SkipPrompt` | Show "`binding` Skip" for `time` seconds |
| `title_card_shown(title, subtitle, hold, fade)` | `TitleStep` | `TitleCard` | Show a title card |
| `quote_shown(text, author, hold, fade)` | `QuoteStep` | `QuoteCard` | Show a quote above the black fade |

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
