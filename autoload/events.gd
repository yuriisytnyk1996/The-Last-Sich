extends Node
## Global signal bus (autoload "Events").
##
## Systems that shouldn't know about each other talk through here.
## Example: a kill zone emits `Events.player_died`, and the room, HUD,
## audio and save system can all react without referencing each other.
## Add new signals here as the game grows.

@warning_ignore("unused_signal")
signal player_died

## Shake the active camera. `trauma` is 0 to 1; requests add up.
@warning_ignore("unused_signal")
signal camera_shake_requested(trauma: float)

## The player's health changed (also sent once when the player spawns).
## The HUD listens to this instead of holding a reference to the player.
@warning_ignore("unused_signal")
signal player_health_changed(current: int, maximum: int)

## The player started a new life: loaded from a save, rested, or came back
## after death. Bars show the new values as they are, without animating.
@warning_ignore("unused_signal")
signal player_respawned

## The player's healing flasks changed: one was drunk or they were
## refilled (also sent once when the player spawns). `level` is the
## flask healing upgrade level. Drives the HUD.
@warning_ignore("unused_signal")
signal player_flasks_changed(current: int, maximum: int, level: int)

## The player pressed heal with no flasks left. The HUD shakes the flasks.
@warning_ignore("unused_signal")
signal player_flasks_empty

## An enemy was killed and the player earned `amount` currency.
## `PlayerWallet` adds it.
@warning_ignore("unused_signal")
signal currency_earned(amount: int)

## The currency the player carries changed (also sent once when the
## player spawns). Drives the HUD.
@warning_ignore("unused_signal")
signal player_currency_changed(amount: int)

## The player's spirit changed: a hit filled it, or a death mark lowered
## its maximum. `full_maximum` is the maximum without death marks, so the
## HUD can show the locked part. Also sent once when the player spawns.
@warning_ignore("unused_signal")
signal player_spirit_changed(current: float, maximum: float, full_maximum: float)

## The number of death marks waiting to be recovered changed (also sent
## once on start). Drives the HUD.
@warning_ignore("unused_signal")
signal death_marks_changed(count: int)

## The player used a rest point. The world makes it the respawn point.
@warning_ignore("unused_signal")
signal rested(rest_point: Node2D)

## The player rested at a rest point and can travel between rest points.
## The world opens the kneel prompt (`KneelScreen`).
@warning_ignore("unused_signal")
signal travel_offered

## The player chose a rest point on the travel map: the one on map cell
## `cell` of the room `room_path`. The world takes them there.
@warning_ignore("unused_signal")
signal travel_requested(room_path: String, cell: Vector2i)

## The player sang the duma of return (`ReturnEffect`). The world takes
## them back to the last rest point they used.
@warning_ignore("unused_signal")
signal return_requested

## The player walked through a `RoomExit`. The world fades out, loads
## `room_path` and places the player at the exit named `exit_name` there.
@warning_ignore("unused_signal")
signal room_change_requested(room_path: String, exit_name: StringName)

## An enemy died. Item effects that react to kills listen to this.
@warning_ignore("unused_signal")
signal enemy_killed

## The player executed an enemy (or a fake execution).
@warning_ignore("unused_signal")
signal enemy_executed

## The player got an item (a pickup, a shop). The HUD names it.
@warning_ignore("unused_signal")
signal item_obtained(item: Item)

## A story flag was set or cleared (`PlayerStory`), or every flag was
## loaded (`flag` is empty then). NPCs check whether they are still there.
@warning_ignore("unused_signal")
signal story_changed(flag: StringName)

## Show a short line at the bottom of the screen, like a found item:
## "A captive is free", "Needs the vault key". The HUD's `ItemToast` shows it.
@warning_ignore("unused_signal")
signal message_shown(text: String)

## The player got a permanent upgrade ("Max health"). The HUD names it.
@warning_ignore("unused_signal")
signal player_upgraded(what: String)

## The player gained or lost a traversal unlock (see `PlayerUnlocks`).
## Room objects gated by one, such as `RevealPlatform`, check again.
@warning_ignore("unused_signal")
signal player_unlocks_changed

## A boss fight started (`BossArena`). The HUD shows the boss bar.
@warning_ignore("unused_signal")
signal boss_fight_started(boss_name: String, current: int, maximum: int)

## The boss in the current fight was hurt. Drives the boss bar.
@warning_ignore("unused_signal")
signal boss_health_changed(current: int, maximum: int)

## The boss fight ended: the boss died, or the player did. The HUD hides
## the boss bar.
@warning_ignore("unused_signal")
signal boss_fight_ended

## A duma started or stopped running. `fraction_left` is 1 when it starts
## and 0 when it ends. The HUD shows it under the spirit bar.
@warning_ignore("unused_signal")
signal duma_time_changed(fraction_left: float)

## The duma button was pressed without enough spirit (or no duma worn).
## The HUD flashes the spirit bar.
@warning_ignore("unused_signal")
signal spirit_short
