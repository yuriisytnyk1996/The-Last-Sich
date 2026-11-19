# Debug console

A command line over the game for testing: turn on god mode, give items, currency and upgrades, jump to any room, set story flags, reveal the map, slow the game down. It saves the trip through the world, and the grinding, that testing one room or one quest stage would otherwise take. It exists in debug builds only (the editor, debug exports); release builds never create it.

## How it works

1. **Opening.** `DebugConsole` (`autoload/debug_console.gd`) watches **F1** in `_input`, before the game and the menus see it, so it works anywhere: in play, over the pause menu, on the title screen. F1 or Escape closes it (Escape hides an open hint list first). The key is reserved, so it can't be bound to an action.
2. **Pausing.** Opening pauses the tree, so typing doesn't move the player, and closing puts the pause back as it was: a console opened over the pause menu leaves the game paused. While it is open, `ConsoleView` keeps every key and `DebugConsole` keeps every gamepad press from reaching the game or the menu behind it.
3. **Full resolution.** The game draws at 640×360 and scales that up, which would blur small text. So on opening, `ConsoleBackdrop` (`ui/debug/console/console_backdrop.gd`) takes a picture of the last frame, turns the window's content scaling off (`Window.content_scale_mode`, the window then renders at its native size), and shows the picture scaled exactly as the game was: by a whole number with integer stretch, as large as fits otherwise, centred on black. Nothing seems to move, and the console text lands on real screen pixels. Closing puts the scaling back. The game is paused anyway, so a still picture loses nothing, but changes made by commands (currency on the HUD, a killed enemy) only show once the console closes. The console's layer (129) is above the brightness and CRT pass (128), since the picture already has them. Headless runs have no frame, so there the console stays at the game's resolution.
4. **The panel.** `ConsoleView` (`ui/debug/console/console_view.gd`) is a fixed box along the top of the screen: `LINES_SHOWN` (17) lines of output above, the command line below. It doesn't grow or shrink with the text: the output keeps the last `MAX_LINES` lines and scrolls, jumps to the end whenever a line is written, and **PageUp** / **PageDown** scroll it half a box. Its text is selectable. Its text is a monospace system font (Menlo, Consolas, DejaVu Sans Mono, whichever the system has) so columns line up. The box's height follows from it, and the text is sized from the window height: the height divided by `LINES_PER_SCREEN`, 22 px at 1080p. It is built in code and never translated, so debug text stays out of the POT.
5. **Focus.** The command line never loses the keyboard. It keeps editing after Enter (`keep_editing_on_text_submit`), so the next command can be typed at once, and whenever focus leaves it while the console is open (a click elsewhere, a menu behind trying to recover its focus), it takes it back.
6. **Typing.** `ConsoleInput` (the command line) keeps the last `HISTORY_SIZE` lines run in `user://console_history.txt`, so **Up** and **Down** step through them across runs. **Tab** completes the word being typed: a command name, or an argument the command knows (item ids, room names, set flags, upgrade kinds). With several choices it completes the common start and prints them all.
7. **Hints.** While something is typed, a list drops over the game under the command line (`ConsoleHints`, `ui/debug/console/console_hints.gd`) and follows every key, Tab and history step. During the first word it lists the commands whose name starts with it, with their summaries (an alias shows as `speed (timescale)`). After it, the command's forms, narrowed to the subcommand once its word is done (`item give ` shows only the give form), then one `›` row per value that may go at the cursor, filtered by what is typed (`MAX_VALUES` of them, then how many more). Nothing typed, or nothing matching, hides it.
8. **Picking from the hints.** While the list holds commands or values, **Down** and **Up** move a highlight over them (`ConsoleHintBox`, `ui/debug/console/console_hint_box.gd`), skipping the usage lines and wrapping around; from nothing, Down starts at the top and Up at the bottom. **Tab** or **Enter** puts the highlighted word in place of the one being typed, followed by a space, without running the line: the next Enter runs it. **Esc** hides the list first and closes the console on the next press. A line recalled from history doesn't open the list, so Up and Down keep walking the history until something is typed; with nothing typed they always walk the history.
9. **Running.** Enter hands the line to `ConsoleShell` (`ui/debug/console/console_shell.gd`). It splits the line on spaces and finds the command by its first word, case ignored: an exact name, or the start of a name when only one command has it (`mon` runs `money`; `s` lists `skill`, `save`, `timescale`). The rest of the words go to the command's `run()`, with their case kept, since story flags and item ids are matched as typed. Several commands can share a line, split by `;`, and run in turn: `god; heal; money 5000`.
10. **Colours.** The typed line is echoed in gold, answers in white, errors in red (an unknown command or id, `ConsoleCommand.error()`), and usage and Tab choices dimmed (`ConsoleShell` colours).
11. **In game only.** Most commands need the running `World` (`ConsoleCommand.needs_game`). Outside it, on the title screen, they answer "Only while playing". `help`, `clear` and `timescale` work anywhere.
12. **Changes go through the game's own paths**, so everything reacts as in play: items through `PlayerInventory.add()` (toast, first-of-a-kind tips), flags through `PlayerStory` (`Events.story_changed`, NPCs, toggles, the story autosave), rooms through `Events.room_change_requested` (the usual fade). Nothing is written to disk until the game saves (a rest, a death, a story change, or `save`).

## Commands

| Command | What it does |
|---|---|
| `help [command]` | Lists every command, or shows one command's forms. Also `?` |
| `clear` | Empties the output. Also `cls` |
| `god` | Toggles god mode: no hit lands on the player (`Hurtbox.immune`), parryable or not. Pits still kill. Off again in a new game |
| `heal` | Fills health, flasks and spirit |
| `money [amount]` | Shows the currency, or adds it (a negative amount takes it away). Also `currency` |
| `item list [kind]` | Every item, `*` for owned. Kinds: charm, blade, keepsake, relic, duma, quest |
| `item give <id\|all>` | Gives one item, or every item (`PlayerInventory.add_all()`) |
| `item take <id>` | Takes an item away |
| `skill list` | Every skill with tier and cost, `*` for learned, and the open tier |
| `skill all` / `skill reset` | Learns every skill and opens every tier (like F9) / forgets them all. Currency isn't given back |
| `skill tier` | Opens the next tier |
| `upgrade [kind] [times]` | Shows the upgrades so far, or adds permanent upgrades: `health`, `spirit`, `flasks`, `flask_heal` |
| `room [name] [exit]` | Lists the rooms (`>` for the current one), or goes to one: its spawn point, or the exit named. Also `go` |
| `kill [player]` | Kills every enemy in the room, bosses too (the fight ends as a win), or the player |
| `flag list [start]` | The set story flags, or those starting with `start` |
| `flag set\|clear\|test <flag>` | Sets, clears or checks a story flag |
| `counter [name] [amount]` | Lists the story counters, shows one, or raises it. Counters only grow |
| `map reveal` | Reveals every map cell of every room in the map catalog |
| `marks [clear]` | Shows the death marks, or removes them all and lifts the penalty, like a free cleanse |
| `tips reset` | Forgets the seen tips: each shows again the next time it comes up |
| `save` | Writes the slot now, without healing or moving the respawn point |
| `timescale [speed]` | Shows or sets the game speed, 0.05 to 4 (1 is normal). Also `speed` |

## Files

| File | Role |
|---|---|
| `autoload/debug_console.gd` | `DebugConsole` autoload: F1, pausing, owns the shell and the panel |
| `ui/debug/console/console_shell.gd` | `ConsoleShell`: the command list, finding a command, running a line, Tab completion |
| `ui/debug/console/console_command.gd` | `ConsoleCommand`: base of every command (names, summary, usage, `run()`, `complete()`) |
| `ui/debug/console/console_view.gd` | `ConsoleView`: the panel, output and command line, font size, keeping focus |
| `ui/debug/console/console_backdrop.gd` | `ConsoleBackdrop`: the still picture of the game, native resolution while open |
| `ui/debug/console/console_hints.gd` | `ConsoleHints`: what the hint list shows for the typed text, and the word each entry puts in |
| `ui/debug/console/console_hint_box.gd` | `ConsoleHintBox`: the hint list, its keyboard highlight |
| `ui/debug/console/console_input.gd` | `ConsoleInput`: the command line, history, Tab, PageUp / PageDown, picking hints, editing after Enter |
| `ui/debug/console/help_command.gd`, `clear_command.gd` | Console commands |
| `ui/debug/console/player/` | Player commands: god, heal, money, item, skill, upgrade |
| `ui/debug/console/world/` | World commands: room, kill, flag, counter, map, marks, tips, save, timescale |

Two small hooks outside the console: `Hurtbox.immune` (ignores every hit, for `god`) and `HitStop.normal_scale` (the speed a hit-stop freeze ends at, for `timescale`, so a freeze doesn't reset the speed to 1).

## Tuning

| Value | Default | Effect |
|---|---|---|
| `DebugConsole.TOGGLE_KEY` | F1 | Opens and closes the console |
| `ConsoleView.MAX_LINES` | 200 | Lines the output keeps |
| `ConsoleInput.HISTORY_SIZE` | 100 | Lines kept in `user://console_history.txt` |
| `ConsoleHints.MAX_COMMANDS`, `MAX_VALUES` | 10, 8 | Commands listed while the name is typed, value rows listed after it |
| `ConsoleView.LINES_SHOWN` | 17 | Output lines the box shows; older ones scroll |
| `ConsoleView.LINES_PER_SCREEN` | 48 | Text size is the window height divided by this (22 px at 1080p) |
| `ConsoleView.MIN_FONT_SIZE` | 12 | Smallest text size, for small windows |
| `TimescaleCommand.MIN_SCALE`, `MAX_SCALE` | 0.05, 4 | Range of `timescale` |

## Extending

To add a command:

1. Create `ui/debug/console/<player|world>/<name>_command.gd` extending `ConsoleCommand`.
2. In `_init()`, set `names` (the first is listed by `help`, the others are aliases), a one-line `summary` and one `usage` line per form. Set `needs_game = false` if it works without the `World`.
3. Do the work in `run(args)`. Use `world()` and `player()` to reach the game, `write()` to answer, `error()` when something is wrong or missing, and `show_usage()` after a wrong call. Go through the game's own methods and signals rather than changing state behind them. A command that changes the room or starts a transition emits `shell.close_requested` first, so the transition runs unpaused.
4. Override `complete(index, args)` to offer words for Tab and the hint list at argument `index`. Start each `usage` line with the command name and subcommand (`item give <id>: ...`), so the hints can narrow to it.
5. Add the script to `ConsoleShell.COMMANDS`, in the order `help` should list it.

Keep debug text out of `tr()`: the console isn't translated.

## Known limitations

- The game must run as a debug build; there is no way to turn the console on in a release export.
- `map reveal` counts every cell at once, but rooms never entered are drawn only after a first visit, and cells behind an unbroken secret wall stay hidden.
- Typed lines are split on spaces and `;`, so arguments can't contain either. No id in the game has one.
- Resizing the window while the console is open keeps the text size it opened with; reopening resizes it.
- There is no command to place an enemy or fly through walls yet.
