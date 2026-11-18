# Cutscenes

Scripted scenes played inside a room. A cutscene takes control away from the player, plays a list of steps (walk the player somewhere, glide the camera to a point, play a conversation, open a gate, show a title or a quote on black) and hands control back. They carry the story: arrivals in new places, ambushes, boss intros, endings.

A cutscene is a list of small step resources, not an animation timeline. Each step is one `.gd` file with a `play()` and a `skip()`, so a new kind of step is a new file and never a change to the runner.

## How it works

1. **Start.** A `Cutscene` node (`components/cutscene/cutscene.gd`) sits in a room's `Logic`. It starts from one of:
   - a `CutsceneTrigger` child: an area the player walks into, or, with `press_interact` on, presses interact in (it shows its `Prompt` only while the cutscene can still play);
   - `play_on_enter`: when the room is entered, `enter_delay` seconds after the transition's fade in;
   - a signal: `source` and `signal_name`, as with a [`StoryTrigger`](/systems/story);
   - a script calling `play()`, such as a [`BossArena`](/systems/bosses) with an `intro`.

   `can_play()` must hold: no other cutscene is running, the player is alive, `flag` isn't set yet and `condition` holds.
2. **Taking control.** `play()` puts the cutscene in the `Cutscene.PLAYING_GROUP` group (`cutscenes`) and sends `Events.cutscene_started(letterbox)`. `CinematicBars` hides the HUD and slides the letterbox bars in. `PlayerScripted.take()` puts the player in the `Scripted` state: input is ignored and the hurtbox is off, so nothing can hurt them. With `freeze_enemies` on, every enemy in the room is switched off (`PROCESS_MODE_DISABLED`) and stays exactly where it is.
3. **Steps.** The steps play in order. A step with `wait` on (the default) finishes before the next one starts. With `wait` off, the next step starts at once and this one runs alongside it: the keeper walks away while the camera glides to the idol. Paths in the steps (`to`, `node`) are read from the cutscene node, so `../CutsceneMarks/IdolView` is a marker beside it in `Logic`.
4. **The end.** Once every step is over, the camera glides back to the player (`camera_return_time`) if a step left it away. Enemies are let go, the player gets control back (Idle, or Fall in the air; presses made during the cutscene are dropped), `flag` is set in [`PlayerStory`](/systems/story) and `Events.cutscene_ended` brings the HUD back.

### Skipping

While a cutscene plays it takes the `pause`, `map` and `inventory` buttons, so no menu opens over it. The first press of pause shows "[Esc] Skip" (the current binding, keyboard or gamepad) in the bottom right corner for `skip_offer_time`. A second press in that time skips:

1. The screen fades to black (`skip_fade_time`) and `Events.cutscene_skipped` hides any title or quote card.
2. The running steps are cut short. Every wait goes through `CutsceneRun.wait()` or `CutsceneRun.until()`, which return at once on a skip.
3. `skip()` is called on every step that didn't finish, in order. It leaves the world as the step would have: `WalkStep` puts the player on the spot, `CallStep` opens the gate, `StoryStep` gives the reward.
4. The camera goes back to the player and the screen fades back in.

A conversation pauses the game, so a cutscene can't be skipped while its text box is open. A cutscene with `skippable` off ignores the presses.

### Playing once

With a `flag`, the cutscene plays once per save slot: the flag is set when it ends, skipped or not, and `can_play()` is false from then on. The story flags are saved at once by `StoryAutosave`, so quitting halfway through a room doesn't replay a cutscene that already ended. The world a cutscene changes must be rebuilt from flags too, because the cutscene doesn't play again: the kurgan's gate has a [`StoryToggle`](/systems/story) that opens it once `kurgan_ambush_seen` is set, and the idol's eyes show once `kurgan_idol_woken` is.

### Camera

`CameraDirector` (`components/camera/camera_director.gd`) sits under the player's `Camera2D`, next to `CameraShake`. `pan_to()` takes the camera off the player (`top_level`, smoothing off) and glides its centre to a point. `glide_home()` glides back over the player and `release()` hands the camera back. The room's camera limits still apply, and every point is clamped to them first, so a glide never stalls against a wall and the hand-back never jumps. Shake still works while the camera is away.

## Steps

All steps extend `CutsceneStep` (`components/cutscene/cutscene_step.gd`) and live in `components/cutscene/steps/`. Every step has `wait` (default on).

| Step | Does | Skipped |
|---|---|---|
| `WalkStep` | Walks the player to `to` (only its x), then turns them to `facing`. Without `to`, only turns. A wall in the way ends the walk | Puts the player on the spot |
| `CameraStep` | Glides the camera to `to` over `duration` and holds it. Without `to`, glides back to the player, who has the camera again | Nothing: the end of the cutscene gives the camera back |
| `DialogueStep` | Plays a [`Dialogue`](/systems/story) in the usual text box, which pauses the game. `speaker` is used unless the conversation names one | Applies the conversation's own `outcome` (answers can't be guessed) |
| `CallStep` | Calls `method` with `arguments` on `node`: `set_open` `[true]` on a gate, `show` on a hidden node | Calls it then, unless `on_skip` is off |
| `MoveStep` | Moves `node` (an NPC) to `to` in a straight line over `duration`, turning its `Visual` toward the way it goes | Puts the node on the spot |
| `StoryStep` | Applies a `StoryOutcome`: a flag a `StoryToggle` reacts to at once, a reward, a message | Applies it then |
| `TitleStep` | Shows a title card (`TitleCard`): `title`, a line and `subtitle`, for `hold` seconds after a `fade` in, then a fade out. Lasts as long as the card | Nothing: the card hides at once |
| `QuoteStep` | Shows `text` and `author` (`QuoteCard`) above everything, the black fade included | Nothing: the card hides at once |
| `FadeStep` | Fades the screen to black (`to_black` on) or back over `duration` | Nothing: a skip fades back in on its own |
| `ShakeStep` | Shakes the camera by `trauma` | Nothing |
| `WaitStep` | Waits `seconds` | Nothing |

For a quote on a black screen: `FadeStep` to black, `QuoteStep`, whatever should happen unseen (a `MoveStep` with `wait` off, a `StoryStep`), then `FadeStep` back. A cutscene that fades to black must fade back in before it ends.

## The test kurgan

`levels/rooms/test_kurgan.tscn` is a wide dusk room (1920×360, zone "Kurgan") behind a door at the east end of the test barracks. It shows every step:

| Cutscene | Starts | Steps |
|---|---|---|
| `Arrival` | `play_on_enter`, once (`kurgan_arrival_seen`) | The player walks in from the door. Title card "The Old Kurgan". Camera to the Grave keeper, who speaks. Camera across the room to the stone idol on the burial mound. `StoryStep` sets `kurgan_idol_woken`, so the idol's eyes light up at once. Shake, a warning about the raiders, camera back |
| `Ambush` | Walking into its trigger before the palisade, once (`kurgan_ambush_seen`) | The player turns to the gate. Camera to the gate, a raider shouts. `CallStep` opens the gate. `freeze_enemies` is off, so the two raiders behind it come out while the camera returns |
| `Vigil` | Interact at the idol, once the ambush has played, once (`kurgan_vigil_done`) | The player walks up to the idol. The keeper walks to the foot of the mound alongside (`MoveStep`, `wait` off). Fade to black, a quote cut in the stone, 250 currency (`StoryStep`), fade back, the keeper speaks |

The keeper is two NPCs: `KeeperRoad` on the road while `kurgan_vigil_done` isn't set, `KeeperMound` at the foot of the mound once it is. The vigil walks the first one to where the second one stands, so the swap when the flag is set at the end can't be seen.

The test arena's Otaman has an intro too (`Logic/Intro`, once, `otaman_intro_seen`): once the gates shut, the camera glides to the boss, the screen shakes, the title card "Otaman / Master of the burned Sich" shows, and the camera comes back before the roar. See [Bosses](/systems/bosses#intros).

## Files

| File | Role |
|---|---|
| `components/cutscene/cutscene.gd` | `Cutscene`: starts, takes control, plays the steps, skips, hands control back |
| `components/cutscene/cutscene_run.gd` | `CutsceneRun`: one playing. The player, node lookups, waits that end on a skip, which steps finished |
| `components/cutscene/cutscene_step.gd` | `CutsceneStep`: base of every step (`wait`, `play()`, `skip()`) |
| `components/cutscene/cutscene_trigger.gd` | `CutsceneTrigger`: walk-in or interact area that starts its parent cutscene |
| `components/cutscene/steps/` | One file per step (table above) |
| `components/camera/camera_director.gd` | `CameraDirector`: takes the camera off the player and glides it |
| `actors/player/abilities/scripted.gd` | `PlayerScripted`: take and release control, walk to a spot, walking tuning |
| `actors/player/states/scripted.gd` | The `Scripted` player state: no input, hurtbox off, the walk |
| `ui/cutscene/cinematic_bars.gd` | Letterbox bars; hides the HUD during a cutscene |
| `ui/cutscene/fading_card.gd` | `FadingCard`: base for the cards below (fade in, hold, fade out, gone on a skip) |
| `ui/cutscene/title_card.gd` | Title, line and subtitle in the middle of the screen |
| `ui/cutscene/quote_card.gd` | Quote and author, drawn above the black fade |
| `ui/cutscene/skip_prompt.gd` | "[Esc] Skip" after the first press of pause |
| `levels/rooms/test_kurgan.tscn` | The test room with the three cutscenes |
| `actors/npcs/keeper/` | The Grave keeper NPC and its conversations |

The bars and the title card are on the world's `CutsceneLayer` (layer 9: over the HUD, under the black fade). The quote card and the skip prompt are on `CutsceneOverlay` (layer 11: over the black fade).

## Tuning

### Cutscene

| Value | Default | Effect |
|---|---|---|
| `steps` | empty | The steps, in order |
| `flag` | empty | Set when it ends; while set, it doesn't play. Empty: plays every time |
| `condition` | none | Plays only while this holds |
| `play_on_enter` | off | Plays when the room is entered |
| `enter_delay` | 0.4 | Seconds after the fade in before a `play_on_enter` cutscene starts |
| `source` / `signal_name` | none | Plays when this signal fires |
| `letterbox` | on | Slides the bars in (the HUD hides either way) |
| `skippable` | on | Pause twice skips |
| `freeze_enemies` | on | Stops the room's enemies while it plays |
| `camera_return_time` | 0.6 | Seconds for the camera to come back if the last step left it away |
| `skip_fade_time` | 0.3 | Seconds of each half of the fade that covers a skip |
| `skip_offer_time` | 2.0 | Seconds a second press of pause still skips |

### PlayerScripted

| Value | Default | Effect |
|---|---|---|
| `walk_speed_factor` | 0.6 | Walking speed in a cutscene, as a share of the run speed |
| `arrive_distance` | 1.0 | Stops this close to the spot (px) |

### CinematicBars

| Value | Default | Effect |
|---|---|---|
| `bar_height` | 30 | Height of each bar once in (px) |
| `slide_time` | 0.4 | Seconds to slide in or out |

### TitleCard, QuoteCard, SkipPrompt

| Value | Default | Effect |
|---|---|---|
| `TitleCard.height` | 0.32 | Title position from the top, as a share of the screen height |
| `TitleCard.line_width` | 120 | Width of the line under the title (px) |
| `QuoteCard.width` | 360 | Text width before it wraps (px) |
| `SkipPrompt.fade` | 0.15 | Seconds to fade in and out |

## Extending

**A cutscene in a room:** add a `Node2D` with `cutscene.gd` to the room's `Logic`, and `Marker2D`s for the spots it uses (a `CutsceneMarks` node keeps them together). Add steps to `steps` in the Inspector and point their paths at the markers, from the cutscene node (`../CutsceneMarks/Spot`). Give it a `flag` unless it should play every time, then pick how it starts: `play_on_enter`, a `CutsceneTrigger` child with a shape (mask `player`, no layer, as in the kurgan), or `source` and `signal_name`.

**A boss intro:** add a cutscene next to the `BossArena` and set it as the arena's `intro`. It plays after the gates shut and before the boss wakes. Give it a flag, so a second attempt goes straight into the fight.

**A new kind of step:** add `components/cutscene/steps/<name>_step.gd` extending `CutsceneStep`. Do the work in `play(run)`, waiting only through `run.wait()` and `run.until(signal)`, and put the world in its end state in `skip(run)`. Use `run.memory[self]` for anything a skip has to stop (a tween). Add it to the steps table above.

**Rebuilding the room after a cutscene:** a cutscene plays once, so anything it changes must also follow from a flag on the next visit. A `StoryStep` or the cutscene's own `flag`, together with a `StoryToggle` on the node, keeps the two in step.

## Known limitations

- No animations for the scripted walk, the NPCs or the idol: placeholder rectangles and polygons, the default font on the cards, no sounds or music cues.
- Steps run one list; there is no branching inside a cutscene. Branch with two cutscenes and their `condition`s, or with answers in a `DialogueStep`.
- Walks are horizontal only. A walk across a gap or up a step stops at it; spots must be on the same floor as the player.
- `MoveStep` glides a node in a straight line and doesn't animate it walking or use physics, so it suits NPCs and props, not enemies.
- Leaving the room mid-cutscene isn't handled: keep walk spots away from exits.
- No zoom: the game is pixel perfect at one scale.
