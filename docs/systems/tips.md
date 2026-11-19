# Tips

"How to play" cards: a short framed text that pauses the game the first time something new comes up (the first finisher, the first death, the first charm), so the player learns a mechanic at the moment it matters instead of from a manual. Each card shows once per save slot. Seen cards can be read again from the pause menu, and the whole feature can be turned off in the options.

## How it works

1. **A tip** is a `Tip` resource (`components/tips/tip.gd`), one `.tres` per card in `levels/tips/`: an `id` (saved once seen), a `title`, a `text`, an optional `image` shown above the text, and `known_from_start` (listed in the pause menu before it was ever shown). The text names actions in braces, `{interact}`, and `formatted_text()` replaces each with the key or button bound to it right now (`[E]`, `[Y]`), so rebinding never leaves a card out of date.
2. **Asking for a tip.** Anything sends `Events.tip_requested(tip)`; a `StoryOutcome` with a `tip` does it when applied, so conversations and `StoryTrigger`s can show one. `TipLog` (`levels/tip_log.gd`, a node in `world.tscn`) queues it unless tips are off, it was already seen, or it is already queued.
3. **Showing it.** `TipLog._process()` only runs while the game isn't paused. Each frame it takes the next queued tip, marks it seen, and opens a `TipScreen` in a `PausingMenu` made on the spot. A request made during a shop, a conversation, a room transition or another card waits until the game runs again, so cards never stack or cut into a menu.
4. **The card.** `TipScreen` (`ui/menus/tips/tip_screen.gd`) fades in over the tinted, paused game (`FADE_IN_TIME`) to `PLAY_ALPHA`, slightly see-through, with one **Got it** button (or back). Closing it fades it out (`FADE_OUT_TIME`), then closes the menu, which unpauses a frame later like every pausing menu.
5. **Keyboard or gamepad.** `TipLog` watches gameplay input (`_input`, so only while the game runs) and remembers whether the last press came from a gamepad, so a card opens with that device's bindings. An open card watches input itself (`Tip.device_of()`) and rewrites its text as soon as the player switches device.
6. **Reading them again.** Once any tip has been seen, the pause menu shows **Tips** between Map and Options. It opens a browsing `TipScreen`: a `Tip` row (`1 / 5`) that left and right turn through every seen tip (and those `known_from_start`), in the order of `TipLog.all`, and **Back**. Browsing cards are opaque and don't fade.
7. **Saving.** `TipLog` is a global save system (`save_id` `tips`) that saves the seen ids: `{"seen": ["parry", "death_mark"]}`. Seen tips belong to the slot, so a new game shows them again. They're written with the next save (a rest, a death, a story change). A tip seen just before quitting without saving shows once more. Loading also drops any queued request: systems that load before `TipLog` (a worn duma) may ask for tips that turn out to be seen.
8. **Turning them off.** Options > Accessibility > **Tips** (`AccessibilitySettings.tips`). While off, nothing is shown **or marked seen**: turning tips back on later still shows each card the first time it comes up.

### What shows a tip

| Tip | When | Asked by |
|---|---|---|
| `execution` Finishers | A finisher appears for the first time (an enemy on its knees, a fake execution), after `tip_delay` | `Execution.tip`, set in `execution.tscn` |
| `death_mark` Death marks | The first death | `TipLog.first_death_tip` on `Events.player_died` |
| `death_marks_more` Clearing marks | The second death | `TipLog.second_death_tip` |
| `charms` Charms | The first charm obtained | `TipLog.charm_tip` on `Events.item_obtained` |
| `blades` Blades | The first blade | `TipLog.blade_tip` |
| `relics` Relics | The first relic | `TipLog.relic_tip` |
| `dumas` Dumas | The first duma **worn** (it explains singing, so finding one isn't enough) | `TipLog.duma_tip` on the `inventory`'s `changed` |
| `captives` Captives | The first captive freed | The `StoryOutcome` of `captive_cage.tscn` |
| `parry` Parry | Walking past the training dummy in the test room | A `TipArea` |
| `healing` Healing flasks | Walking toward the test room's raiders | A `TipArea` |

A death tip shows once the player is back on their feet: the respawn transition pauses the game, so the card waits for it. An item bought in a shop gets its tip once the shop closes.

## Files

| File | Role |
|---|---|
| `components/tips/tip.gd` | `Tip`: id, title, text, action names replaced by bindings |
| `levels/tips/*.tres` | The cards |
| `levels/tip_log.gd` | `TipLog`: queue, shows each tip once, the watched events, seen tips, global save system `tips` |
| `levels/objects/tips/tip_area.gd` | `TipArea`: asks for its tip when the player walks in |
| `ui/menus/tips/tip_screen.gd` | `TipScreen`: the card, in play or browsing |
| `components/interaction/execution.gd` | `Execution.tip` and `tip_delay` |
| `components/story/story_outcome.gd` | `StoryOutcome.tip`: a scripted tip |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `Execution.tip_delay` | 0.6 | Seconds after a finisher appears before its tip shows, so the player sees the enemy kneel first |
| `TipScreen.FADE_IN_TIME` | 1.0 | Seconds the card takes to fade in during play |
| `TipScreen.FADE_OUT_TIME` | 0.5 | Seconds it takes to fade out when closed |
| `TipScreen.PLAY_ALPHA` | 0.8 | Opacity of the card during play, so the paused game shows through |
| `TipScreen.BOX_WIDTH` | 320 | Width of the card (px) |
| `AccessibilitySettings.tips` | On | Off: no cards are shown or marked seen |

## Extending

**A new tip:** add a `.tres` in `levels/tips/` with a new `id` (never rename a shipped one), and add it to `TipLog.all` in `world.tscn` where it should be listed. Then ask for it:

- **in a room**: place a `TipArea` (`levels/objects/tips/tip_area.gd`) on an `Area2D` with a `CollisionShape2D` child and set its `tip`. It sets its own layer and mask,
- **on a game event**: add an export to `TipLog` and request it from a handler of the `Events` signal,
- **from a conversation or room event**: set `tip` on the `StoryOutcome` of a `Dialogue`, `DialogueChoice` or `StoryTrigger`. The tip shows after the conversation closes,
- **from any script**: `Events.tip_requested.emit(tip)`. Asking more than once is safe.

## Known limitations

- No card has a picture yet: `image` is ready, the art isn't. No card is `known_from_start` either.
- The gamepad names are generic (A, B, X, Y, LB...), not the layout of a particular pad.
- There is no debug command to list or force a tip. The [debug console](/systems/debug-console)'s `tips reset` forgets the seen ones, and a new slot (F8) shows them all again.
