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

## The world put the player somewhere new behind the black screen (a room
## exit, travel, the Road Home, a respawn), before fading back in. Things
## left on the spot that should come along (a warding circle) move here.
@warning_ignore("unused_signal")
signal player_arrived

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
## Already translated: the sender passes the text through `tr()`.
@warning_ignore("unused_signal")
signal message_shown(text: String)

## Show a "how to play" card the first time this tip comes up. `TipLog`
## shows it once the game runs (unless it was seen or tips are off).
@warning_ignore("unused_signal")
signal tip_requested(tip: Tip)

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

## A `Cutscene` took the player's control. The HUD hides and, with
## `letterbox`, the cinematic bars slide in.
@warning_ignore("unused_signal")
signal cutscene_started(letterbox: bool)

## The cutscene ended (played out or skipped): the player has control
## again, the bars slide out and the HUD comes back.
@warning_ignore("unused_signal")
signal cutscene_ended

## The player skipped the cutscene and the screen is black. Title and
## quote cards hide at once.
@warning_ignore("unused_signal")
signal cutscene_skipped

## Pause was pressed once in a skippable cutscene: "`binding` Skip" shows
## for `time` seconds, and a second press in that time skips.
@warning_ignore("unused_signal")
signal cutscene_skip_offered(binding: String, time: float)

## A cutscene shows a title card: a zone's name, a boss's name. It fades
## in over `fade` seconds, stays `hold` seconds and fades out.
@warning_ignore("unused_signal")
signal title_card_shown(title: String, subtitle: String, hold: float, fade: float)

## A cutscene shows a quote over the screen, usually faded to black first.
@warning_ignore("unused_signal")
signal quote_shown(text: String, author: String, hold: float, fade: float)
