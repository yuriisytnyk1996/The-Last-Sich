# NPCs, dialogue and quests

People to talk to, conversations with answers, and quests that remember what the player has done. There is no quest object: a quest is a handful of **story flags** and **counters** that conversations and room events change, and that NPCs, answers and room objects check. The same few pieces build every kind of quest below.

## How it works

1. **Story flags and counters.** `PlayerStory` (`actors/player/abilities/story.gd`, the player's `Story` node) holds named flags (`kobzar_met`, `kobzar_done`) and named counters (`alms_given`, `letters_delivered`). `set_flag()`, `clear_flag()` and `add_counter()` change them and announce it through `Events.story_changed(name)`. `count_prefix("freed_captive_")` counts numbered flags. Both are saved (save id `story`). A quest's stage is simply which of its flags are set and how high its counters are.
2. **Saved at once.** `StoryAutosave` (`levels/story_autosave.gd`, a child of the `World`) writes the save at the end of any frame the story changed in. Quitting before the next rest can't undo a quest step, a hand-in or its reward. Saving outside a rest point is safe: a load always wakes the player at the last rest point.
3. **Conditions.** A `StoryCondition` (`components/story/story_condition.gd`) checks flags, counters and items. Every part that is set must hold; an empty condition always holds:
   - `all_flags` all set, `no_flags` none set,
   - `owns` all carried now, `lacks` none carried now, `owns_any` at least one carried now,
   - `obtained` all had at some point, even if handed over since (`PlayerInventory.has_obtained()`),
   - `count_prefix` / `count_at_least`: at least N flags starting with the prefix,
   - `counter` / `counter_at_least`: a counter at least N.
4. **Outcomes.** A `StoryOutcome` (`components/story/story_outcome.gd`) is what happens: `set_flags`, `clear_flags`, `take_items` (hand over), `cost` (currency paid), `give_items`, `reward` (currency received), `turn_in` (take every listed item carried and raise `counter` by one for each), `counter` + `counter_add`, a `message` shown at the bottom of the screen (`Events.message_shown`), and a `tip` shown as a card the first time (see [Tips](/systems/tips)). `apply()` does all of it, but only while `can_apply()`: the player has the items and currency it takes.
5. **Conversations.** A `Dialogue` (`components/story/dialogue.gd`) is one `.tres` file: a `speaker` (empty: the NPC's name), `lines` (one per text box), optional `choices` shown on the last line, an `outcome` applied once the last line shows, and a `condition` for when an NPC may start it.
6. **Answers.** A `DialogueChoice` (`components/story/dialogue_choice.gd`) has a `text`, an `outcome`, a `next` conversation (empty: the talk ends) and a `condition`. An answer whose condition fails is hidden. An answer whose outcome can't be paid is shown greyed out, with its price in the text when it has one.
7. **NPCs.** An `Npc` (`actors/npcs/npc.gd`, scene `actors/npcs/npc.tscn`) is an interact area. Pressing interact next to them starts the **first** of their `dialogues` whose condition holds, so the list goes from most specific (a reward waiting, an item brought) to plainest (first meeting, no condition). The NPC and the player turn to face each other. With a `presence` condition the NPC is only there while it holds; they check again on every `Events.story_changed`. Anything with conversations can be an `Npc`: the alms box is one.
8. **The text box.** `DialogueScreen` (`ui/menus/dialogue/dialogue_screen.gd`) plays the conversation in a `PausingMenu`, so the game waits. It sits at the bottom of the view without a backdrop. Each line is typed out at `TYPE_SPEED`; "Next" (or back) while typing shows the whole line, and again goes on. On the last line it applies the conversation's outcome and shows the answers, or a last "Next" that closes it. Picking an answer applies its outcome, then plays its `next` conversation in the same box or closes it. Back never picks an answer.
9. **Room events.** A `StoryTrigger` (`components/story/story_trigger.gd`) applies an `outcome` and sets a `flag` whenever a signal of its `source` (default: its parent) fires, while its `condition` holds. Signals made for it fire only on live events, never when a save restores the object, so nothing counts twice:
   - `Breakable.broken_by_player`: a cage, a wall, a crate broken by the player,
   - `ItemPickup.taken`: an item picked up,
   - `BossArena.boss_beaten`: a boss killed,
   - `Area2D.body_entered` (masking only the player): a place reached. Any signal works; its arguments are ignored.
10. **Room changes.** A `StoryToggle` (`components/story/story_toggle.gd`) shows or hides its `targets` (default: its parent), or opens or closes them (`set_open()`, a `Gate`), by a `StoryCondition`. It checks when the room loads (gates snap into place) and on every `Events.story_changed` (gates move). A hidden node is also switched off (`PROCESS_MODE_DISABLED`), so its collision is gone: a hidden chest can't be opened.
11. **Key items.** A `Lever` with a `key` shows "Needs &lt;key&gt;" when pulled without it. With `takes_key` the first pull uses the key up (saved), and later pulls need none. See [Traversal](/systems/traversal#levers-and-gates).

### Quest types

| Type | How it's built | Test example |
|---|---|---|
| NPC story chain | Conversations that set `<npc>_<stage>` flags; later ones check them | The kobzar |
| Fetch and hand in | A conversation with `owns = [item]`; an answer whose outcome `take_items`, pays a `reward` and sets `<quest>_done` | The kobzar's string |
| Accept or refuse | Two answers; only the accepting one sets `<quest>_asked` | "I'll look for it" / "Find it yourself" |
| Buy from a person | An answer with a `cost` and `give_items` | (pattern only) |
| Hint after an event | A `StoryTrigger` on an area sets `<place>_visited`; a conversation checks it | The kobzar's hint after the crypt |
| Counted set (free N of M) | A `StoryTrigger` per object sets a numbered flag; conversations check `count_prefix` / `count_at_least`, each reward tier guarded by its own `no_flags` | Three captive cages, the elder |
| Collect and turn in | Collectible quest items; an answer with `turn_in` and a `counter`, shown while `owns_any`; reward tiers check the counter | Three Sich letters, the elder |
| Donation total with tiers | Answers with a `cost` and `counter_add`; one conversation per tier checks `counter_at_least` | The alms box |
| Boss or world progress | A `StoryTrigger` on `BossArena.boss_beaten` sets `<boss>_beaten` | The Otaman, the elder's news |
| Quest fails when the world moves on | A `StoryTrigger` with a `condition` (`no_flags = [<quest>_done]`) sets `<npc>_gone`; the NPC's `presence` has `no_flags = [<npc>_gone]` | The kobzar leaves if the Otaman dies first |
| The world changes after a quest | A `StoryToggle` shows a chest or opens a gate by a condition | The kobzar's chest |
| Item-locked door | A `Gate` driven by a `Lever` with a `key` (and `takes_key` to use it up) | (pattern only) |
| Remember a handed-over item | `obtained` instead of `owns` | (pattern only) |

Special challenges with their own rules (a timed run, a chain of trial rooms) still need their own script. They plug into the same pieces: they set flags and counters through a `StoryOutcome`, so conversations, toggles and rewards react to them like to anything else.

### Test content

**The kobzar** (`actors/npcs/kobzar/`, test cave x 220). His conversations, in the order he picks them:

1. `done`: after `kobzar_done`, a closing line.
2. `return`: after `kobzar_met`, while the player carries the **kobza string** and the quest isn't done. "Give him the string" takes it, pays 300, sets `kobzar_done` and goes on to `thanks`. "Not yet" ends the talk.
3. `hint`: after `kobzar_asked` and `crypt_visited`, without the string: where in the crypt to look.
4. `reminder`: after `kobzar_asked`.
5. `intro`: the first meeting. Sets `kobzar_met` once read. "I'll look for it" sets `kobzar_asked`; "Find it yourself" doesn't.

The kobza string lies in the test crypt (x 104). A `VisitedArea` near the crypt's entrance sets `crypt_visited`. Once `kobzar_done` is set, a chest worth 150 appears next to him (`KobzarChest`, shown by a `StoryToggle`). If the Otaman is beaten before the quest is done, the arena's `KobzarLeaves` trigger sets `kobzar_gone` and he is no longer in the cave.

**The elder** (`actors/npcs/elder/`, test room x 496). His first talk (`intro`) sets `elder_met`; after that `idle` says where everything is. Waiting rewards come first:

1. `boss_news`: after `otaman_beaten` (the arena's `OtamanBeaten` trigger), 200 once.
2. `captives_all`: 3 `freed_captive_*` flags, the war drum once.
3. `captives_first`: 1 `freed_captive_*` flag, 150 once.
4. `letters_done`: `letters_delivered` at 3, the guarding edge once.
5. `letters`: while carrying any Sich letter, "Hand over the letters" takes every one carried, adds them to `letters_delivered` and pays 100.

The **captive cages** (`levels/objects/story/captive_cage.tscn`, a `Breakable` with 2 hits that stays broken, in the `captives` group so the [wandering candle](/systems/dumas#companions)'s light can find it) are in the test cave (x 420, `freed_captive_01`), the test crypt (x 300, `freed_captive_02`) and the test barracks (x 680, `freed_captive_03`). Each sets its flag through its `StoryTrigger`'s `flag` and shows "A captive is free". The **Sich letters** (`actors/player/items/quest/sich_letter_1..3.tres`) lie in the test hideout (x 120), the test barracks (x 236) and the test works (x 232).

**The alms box** (`levels/objects/story/alms_box.tscn`, an `Npc`, test crypt x 200) takes 200 or 500 at a time into `alms_given`. At 600 it gives the brass bell (`blessing_1`), at 1500 the healer's knot (`blessing_2`), each once.

## Files

| File | Role |
|---|---|
| `actors/player/abilities/story.gd` | `PlayerStory`: story flags and counters, saved |
| `levels/story_autosave.gd` | `StoryAutosave`: saves the game when the story changes |
| `components/story/story_condition.gd` | `StoryCondition`: checks flags, counters and items |
| `components/story/story_outcome.gd` | `StoryOutcome`: sets flags and counters, moves items and currency, shows a message |
| `components/story/dialogue.gd` | `Dialogue`: one conversation |
| `components/story/dialogue_choice.gd` | `DialogueChoice`: one answer |
| `components/story/story_trigger.gd` | `StoryTrigger`: applies an outcome when a signal fires |
| `components/story/story_toggle.gd` | `StoryToggle`: shows, hides, opens or closes nodes by a condition |
| `actors/npcs/npc.gd`, `npc.tscn` | `Npc`: picks and starts a conversation, presence |
| `actors/npcs/kobzar/`, `actors/npcs/elder/` | The test NPCs and their conversations |
| `levels/objects/story/captive_cage.tscn` | A breakable cage that frees a captive (sets its trigger's `flag`) |
| `levels/objects/story/alms_box.tscn`, `alms/` | The alms box and its conversations |
| `ui/menus/dialogue/dialogue_screen.gd` | `DialogueScreen`: the text box |

## Tuning

| Value | Default | Effect |
|---|---|---|
| `DialogueScreen.TYPE_SPEED` | 60 | Letters typed per second |
| `DialogueScreen.BOX_WIDTH` | 400 | Text box width (px) |
| `DialogueScreen.SCREEN_HEIGHT` | 340 | The box sits at the bottom of a screen this tall (px) |
| `CaptiveCage.hits` | 2 | Hits to break a cage |

## Extending

- **A new NPC:** make a scene inheriting `actors/npcs/npc.tscn` in `actors/npcs/<name>/`, set `display_name`, recolour or replace `Visual`, and list conversations from `actors/npcs/<name>/dialogues/`. Place it in a room's `Logic`.
- **A new quest:** pick flag and counter names (`<quest>_<stage>`) and write the conversations that set and check them. Names are never declared anywhere, so list them on this page.
- **A new counted set:** place one object per member, each with a `StoryTrigger` whose `flag` is numbered (`<set>_01`...), and check `count_prefix` in the reward conversations.
- **A room object that reports to quests:** give it a signal emitted only on live events (not when its save is restored), and put a `StoryTrigger` under it.
- **A room that changes with a quest:** put a `StoryToggle` under the node, or next to gates with `targets` set.
- **A new kind of check or effect:** add an export to `StoryCondition` or `StoryOutcome`. Everything that uses them picks it up.

## Known limitations

- No quest journal: the player can't see their open quests.
- Names are plain strings with no list of known ones, so a typo makes a flag that is never checked.
- Lines can't show numbers ("2 of 3 letters").
- No portraits, voices or text sounds; no cutscenes or walking NPCs.
- No New Game+ yet, so no flags that carry over.
- The flask healer is still a table, not a person.
- Lines aren't translation keys yet.
