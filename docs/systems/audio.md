# Audio

Sound effects and music. Code and scenes only ever name a sound (`&"parry"`). One sound bank says which file plays for each name, so a placeholder can be swapped for a real recording without touching code.

## How it works

### Sound cues

`assets/audio/sound_bank.tres` is a `SoundBank`: a table of **cues** by name. Each cue (`SoundCue`) holds one or more takes of the sound. Every play picks one take at random and shifts its pitch a little, so ten hits in a row don't sound identical.

The `Audio` autoload plays cues:

- `Audio.play_at(cue, position)`: a sound **in the world**. It is panned and fades with distance from the camera (gone at 700 px), and it pauses with the game (menus, tips, room fades).
- `Audio.play(cue)`: a sound **on the screen** (menus, pickups). It has no position and keeps playing while the game is paused.

Players are made once at startup (24 for the world, 8 for the screen) and reused. When they are all busy, the oldest is cut. A cue never has more than `max_voices` copies playing at once, and it can't restart within `cooldown` seconds. This way, a blow that hits three enemies in one frame plays once instead of making a loud spike.

An empty cue name plays nothing. Every sound `@export` can be left empty to silence it. An unknown name warns once in the output.

### Where sounds come from

Most sounds come from a few generic hooks, so new content usually needs no code:

| Hook | Plays | Set in |
|---|---|---|
| `Hitbox.sound` | Each time the hitbox turns on: a swing, a shot leaving the barrel, a slam | The hitbox node |
| `HurtFeedback` sounds | When its hurtbox is hit (`hurt_sound`, plus `crit_sound` on a critical), parries (`parry_sound`), blocks (`block_sound`) or guard-slides (`guard_slide_sound`) | The actor's `HurtFeedback` node |
| `StateSounds` | When a state machine enters a state (`"Jump"`) or makes a given change (`"Fall>Idle"`, which wins over the plain name), plus footsteps every `step_interval` while `step_state` runs | A `StateSounds` node in the actor's scene |
| `Breakable.break_sound` | When a crate, wall or cage breaks | The breakable |
| `Audio.EVENT_CUES` | Global events: item obtained, currency earned, upgrade, rest, not enough spirit, no flasks | `autoload/audio.gd` |
| Menus | `ui_move` when focus moves between buttons (not on a menu's first focus), `ui_accept` when any button is pressed, `ui_back` on cancel | Automatic for every button |

A swing's sound belongs on its hitbox rather than on the attack state, because the hitbox turns on when the blow actually comes out, after the wind-up. A pooled shot plays its sound a frame after it is switched on, once it has been placed at the muzzle.

### Music

The `Music` autoload plays one track at a time on the Music bus. A new track crossfades over 1.5 s; the same track keeps playing. Music keeps going while the game is paused.

- **Rooms:** `Room.music` is the room's track. The world hands it to `Music.set_room_music()` each time a room loads. A room without one keeps whatever is playing, so the rooms of one zone can share a track without each setting it.
- **Bosses:** `BossArena.phase_music` lists a track per boss phase. The first plays as the fight starts (after the intro). The next one comes in, over 0.5 s, when the boss starts its next phase (`Boss.phase_changed`, after the roar). A phase without a track keeps the last one. When the boss dies, the room's track comes back over 3 s; if the player dies, it comes back at once.

Tracks loop. An Ogg imported with **Loop** on loops by itself; any other stream restarts when it ends.

### Volume

Each cue picks its bus (`Effects` by default, `Voice` for speech later). Music uses `Music`. The volume options drive the buses; see [Options](/systems/options).

`default_bus_layout.tres` also holds the mix: a gentle compressor on Effects (threshold -14 dB, ratio 3, 4 ms attack, 140 ms release) so stacked hits and blasts sit together, and a hard limiter on Master (ceiling -0.5 dB) so nothing ever clips.

## Placeholder sounds

Every sound and track in `assets/audio/` is a placeholder synthesised by `tools/placeholder_audio/` (Python standard library only, nothing downloaded or sampled):

- **Sound effects** are mono 44.1 kHz WAV, layered like recorded effects: a short transient, a body and a tail. They use band-limited oscillators, resonant filters, FM synthesis for struck metal (parries, blocks, coins, bells) and two vocal formants for grunts. Some have a short room reverb baked in. Sounds heard over and over have several takes (`step_1.wav` … `step_4.wav`, three hits, three swings) that the cue picks between.
- **Music** is stereo and arranged: Karplus-Strong bandura plucks, a sopilka (wooden flute) with breath and vibrato, detuned string pads, bass, frame drums and a formant choir. Every track runs through a feedback-delay reverb and is mastered to an even loudness with a look-ahead limiter. Notes and reverb wrap around the loop, so it has no seam. Music is encoded to Ogg Vorbis (q8) with ffmpeg when it is installed.

| Track | Feel |
|---|---|
| `steppe` | 84 bpm, D minor: bandura arpeggios, a sopilka tune, strings, bass, wind |
| `kurgan` | 60 bpm: a low drone, a dark choir moving between D minor and E flat, distant bells, wind |
| `boss_1` | 120 bpm, D harmonic minor: kick and frame drums, bass, a bandura riff, string stabs |
| `boss_2` | 140 bpm: the same driven harder, with hats, a choir and a sopilka lead |

```sh
python3 -I tools/placeholder_audio              # everything (about a minute)
python3 -I tools/placeholder_audio sfx          # sound effects only
python3 -I tools/placeholder_audio steppe hit   # just these
```

To use a real sound, add the file (WAV or Ogg) anywhere under `assets/audio/`. Then point the cue's `streams` at it in `sound_bank.tres` (in the inspector), and add more takes to the same cue if you have them. Don't overwrite the placeholder file: re-running the script would overwrite it again. For a music file, turn **Loop** on in the Import dock.

## Files

| File | Role |
|---|---|
| `autoload/audio.gd` | Plays cues from the bank: world and screen players, voice limits, event and menu sounds |
| `autoload/music.gd` | Crossfades music, room and boss tracks |
| `components/audio/sound_bank.gd` | `SoundBank`: cues by name |
| `components/audio/sound_cue.gd` | `SoundCue`: takes, volume, pitch jitter, bus, voice limit, cooldown |
| `components/audio/state_sounds.gd` | `StateSounds`: cues on state changes and footsteps |
| `assets/audio/sound_bank.tres` | The game's cues |
| `assets/audio/sfx/`, `assets/audio/music/` | Sound files (placeholders) |
| `tools/placeholder_audio/` | Generates the placeholder files: `dsp.py` (oscillators, filters, reverb, limiter), `sfx.py` (effect recipes, takes), `music.py` (instruments, arranging), `tracks.py` (the four tracks) |

## Tuning

`SoundCue`:

| Value | Default | Effect |
|---|---|---|
| `volume_db` | 0 | Loudness of this cue |
| `pitch_jitter` | 0.05 | Each play shifts the pitch by up to this fraction, up or down |
| `bus` | Effects | Audio bus |
| `max_voices` | 4 | Most copies playing at once; another cuts the oldest |
| `cooldown` | 0.03 s | Time before the cue can start again |

`StateSounds`:

| Value | Default | Effect |
|---|---|---|
| `sounds` | empty | Cue per state (`"Jump"`) or change (`"Fall>Idle"`) |
| `step_state` / `step_sound` | empty | State that repeats footsteps, and their cue |
| `step_interval` | 0.3 s | Time between footsteps |

`HurtFeedback` sounds: `hurt_sound` `hit`, `crit_sound` `hit_critical`, `parry_sound` `parry`, `block_sound` `block`, `guard_slide_sound` `guard_slide`. The player uses `player_hurt`, breakables and cages `hit_wood`, attack switches `block`.

Constants: `Audio.WORLD_VOICES` 24, `Audio.SCREEN_VOICES` 8, `Audio.HEARING_DISTANCE` 700 px, `Music.FADE` 1.5 s.

## Extending

- **A new sound:** add the file, then add a cue for it to `sound_bank.tres` (a new `SoundCue` under `cues`) and use its name in a hitbox, `HurtFeedback`, `StateSounds` or an `Audio.play_at()` call.
- **A new enemy:** set `sound` on its attack hitboxes and add a `StateSounds` node with at least `"Dead": enemy_death`.
- **A sound for a global event:** add the `Events` signal and its cue to `Audio.EVENT_CUES`.
- **Zone music:** set `music` on the zone's first rooms (any room the player can enter from outside the zone or load into). The others can leave it empty.

## Known limitations

- Every sound and track is a synthesised placeholder. They are meant to make the game readable by ear, not to be final: real recordings and a composed score are still needed.
- No ambience layer (wind, water, crowds) yet, and no reverb per zone.
- No dialogue text blips or voices yet (the Voice bus is unused).
- Enemy wind-ups (telegraphs) and the boss's roar are silent.
- Loading a save in a room without `music` starts in silence until a room with music is entered.
